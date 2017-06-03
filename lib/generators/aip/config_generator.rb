require 'rails/generators'

class Aip::ConfigGenerator < Rails::Generators::Base

  source_root File.expand_path('../templates', __FILE__)

  def create_initializer_config_file
    copy_file 'config/aip.rb', 'config/initializers/aip.rb'
  end

end
