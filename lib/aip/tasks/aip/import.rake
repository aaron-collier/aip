require 'rubygems'
require 'zip'
require 'colorize'

namespace :aip do

  desc 'Import DSpace AIP packages into the repository'
  task :import, [:file] =>  [:environment] do |t, args|

    unless File.exists? ("#{Rails.root}/config/aip_works.yml") # && File.exists? ("#{Rails.root}/config/initializers/aip.rb")
      log.error "AIP Config files not found."
      log.info "Use `rails generate aip:config` to install AIP configuration files."
      abort
    end

    log.info "Starting rake task ".green + "packager:aip".yellow

    unless args[:file]
      log.error "No source input file provided."
      log.info "Use `rake aip:import[\"filename\"]` to import an AIP package."
      abort
    end


    params = { :source_file => args[:file],
               :source_path => File.join(input_path,args[:file]),
               :default_resource_type => Aip.config.default_resource_type
             } or raise "No source input file provided."

    log.info "Loading import package from #{params[:source_file]}"

    log.info params[:source_file]

    unless File.exists?(params[:source_path])
      log.error "Exiting packager: input file [#{params[:source_path]}] not found."
      abort
    end

    unzip_package(params)
    collect_structure_files(params)
    process_structure_files(params[:structure])
    # collect_metadata(params)
    # collect_work_files()
    log.info JSON.pretty_generate(params)

  end
end

def log
  @log ||= Aip::Log.new(Aip.config.output_level)
end

def input_path
  @input_path ||= Aip.config.import_dir
end

def output_path
  @output_path ||= initialize_directory(File.join(input_path, "unpacked"))
end

def complete_path
  @complete_path ||= initialize_directory(File.join(input_path, "complete"))
end

def error_path
  @error_path ||= initialize_directory(File.join(input_path, "error"))
end

def unzip_package(params)

  params[:unpacked_path] = initialize_directory(File.join(output_path, File.basename(params[:source_file], ".zip")))
  params[:files] = Array.new

  Zip::File.open(File.join(input_path,params[:source_file])) do |file_to_extract|
    file_to_extract.each do |compressed_file|
      params[:files] << { :source_file => compressed_file.name }
      unpack_file(file_to_extract,File.join(params[:unpacked_path], compressed_file.name))
    end
  end
end

def unpack_file(compressed_file,file_to_unpack)
  compressed_file.extract(File.basename(file_to_unpack),file_to_unpack) unless File.exist?(file_to_unpack)
end

def collect_metadata(params)
  params.each do |structure_file|
    unless structure_file[:files].nil?
    structure_file[:files].each do |file|
      if file[:source_file] === Aip.config.metadata_file
        collect_parameters(structure_file)
      end
    end
  end
  end
end

def collect_structure_files(params)
  params[:structure] = Array.new
  # mets_data = Nokogiri::XML(File.open(File.join(output_path,File.basename(params[:source_file],'.zip'),params[:files][0][:source_file])))
  mets_data = read_xml(params[:source_file])
  file_list = mets_data.xpath(Aip.config.works['structure']['xpath'],Aip.config.works['structure']['namespace'])
  file_list.each do |file|
    params[:structure] << { :source_file => file.attr('xlink:href') }
  end
end

def process_structure_files(params)
  params.each do |structure_file|
    if File.exist?(File.join(input_path, structure_file[:source_file]))
      unzip_package(structure_file)
      collect_structure_files(structure_file)
      process_structure_files(structure_file[:structure])
      collect_metadata(structure_file[:structure])
    end
  end
end

def collect_parameters(params)

  params[:metadata] = Hash.new {|h,k| h[k]=[]}
  # mets_data = Nokogiri::XML(File.open(File.join(output_path,File.basename(params[:source_file],'.zip'),params[:files][0][:source_file])))
  mets_data = read_xml(params[:source_file])

  Aip.config.works['fields'].each do |field|
    # puts field
    # if field.include? "xpath"
      field[1]['xpath'].each do |current_xpath|
        # puts "#{current_xpath}"
        metadata = mets_data.xpath("#{Aip.config.works['DSpace ITEM']['desc_metadata_prefix']}#{current_xpath}",
                                   Aip.config.works['DSpace ITEM']['namespace'])
        if !metadata.empty?
          if field[1]['type'].include? "Array"
            metadata.each do |node|
              params[:metadata][field[0]] << node.inner_html
            end # metadata.each
          else
            params[:metadata][field[0]] = metadata.inner_html
          end # "Array"
        end # empty?
      end # xpath.each
    # end # field.xpath
  end # typeConfig.each
end # collect_params


def collect_bitstreams
  fileList = @mets_XML.xpath("#{config['bitstream_structure']['xpath']}", config['bitstream_structure']['namespace'])
  fileArray = []

  fileList.each do |fptr|
    fileChecksum = fptr.at_xpath("premis:objectCharacteristics/premis:fixity/premis:messageDigest",
                                 'premis' => 'http://www.loc.gov/standards/premis').inner_html
    originalFileName = fptr.at_xpath("premis:originalName",
                                     'premis' => 'http://www.loc.gov/standards/premis').inner_html.delete(' ')
    dspaceExportedFile = dom.at_xpath("//mets:file[@CHECKSUM='"+fileChecksum+"']/mets:FLocat",
                                      'mets' => 'http://www.loc.gov/METS/')
    # TODO: Error check files by MD5 Hash

    newFileName = dspaceExportedFile.attr('xlink:href')
    File.rename(@bitstream_dir + "/" + newFileName, @bitstream_dir + "/" + originalFileName)
    fileArray << {'file_type' => dspaceExportedFile.parent.parent.attr('USE'),
                  'file_name' => File.join(@bitstream_dir,originalFileName)}
  end # fileList.each

  return fileArray
end # collect_files

def createItem
  parameters = collect_parameters
  puts parameters
  parameters[:id] = ActiveFedora::Noid::Service.new.mint

  resource_type = @default_resource_type
  unless parameters['resource_type'].first.nil?
    resource_type = parameters['resource_type'].first
  end

  parameters.merge(set_item_visibility(parameters['embargo_release_date']))
  puts parameters
  item = Kernel.const_get(config['type_to_work_map'][resource_type]).new(parameters)
  # item.update(params)
  item.apply_depositor_metadata(depositor.user_key)
  item.save
end

def set_item_visibility(embargo_release_date)
  return { "visibility" => "open" } if embargo_release_date.nil?
  return { "visibility_after_embargo" => "open",
           "visibility_during_embargo" => "authenticated" }
end

def getUser(email)
  user = User.find_by_user_key(email)
  if user.nil?
    pw = (0...8).map { (65 + rand(52)).chr }.join
    log.info "Generated account for #{email}"
    user = User.new(email: email, password: pw)
    user.save
  end
  # puts "returning user: " + user.email
  return user
end

def initialize_directory(dir)
  Dir.mkdir dir unless Dir.exist?(dir)
  return dir
end

def read_xml(file)
  Nokogiri::XML(File.open(File.join(output_path,File.basename(file,'.zip'),Aip.config.metadata_file)))
end
