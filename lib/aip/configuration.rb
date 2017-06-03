module Aip
  class Configuration

    attr_writer :default_resource_type
    def default_resource_type
      @default_resource_type ||= "Thesis"
    end

    attr_writer :metadata_file
    def metadata_file
      @metadata_file ||= "mets.xml"
    end

    attr_writer :depositor
    def depositor
      @depositor ||= "acollier@calstate.edu"
    end

    attr_writer :import_dir
    def import_dir
      @import_dir ||= "/Users/acollier/Temp/drew/"
    end

    attr_writer :create_admin_sets
    def create_admin_sets
      @create_admin_sets ||= true
    end

    attr_writer :exit_on_error
    def exit_on_error
      @exit_on_error ||= true
    end

    # output_level: How much will be output to the shell while running
    # quiet - Nothing will be output
    # minimal - a running progress bar will be output
    # verbose - running progress text will be output
    attr_writer :output_level
    def output_level
      @output_level ||= 'verbose'
    end

    attr_writer :include_thumbnail
    def include_thumbnail
      @include_thumbnail ||= false
    end

    attr_writer :default_university
    def default_university
      @default_university ||= "ENTER UNIVERSITY BEING IMPORTED"
    end

    attr_writer :works
    def works
      @works ||= Rails.application.config_for(:aipworks)
    end


  end
end
