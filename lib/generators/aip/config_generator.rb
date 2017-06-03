require 'rails/generators'

class Aip::ConfigGenerator < Rails::Generators::Base

  source_root File.expand_path('../templates', __FILE__)

  def create_initializer_config_file
    copy_file 'config/aip.rb', 'config/initializers/aip.rb'
    copy_file 'config/aip_works.yml', 'config/aip_works.yml'
  end
end
