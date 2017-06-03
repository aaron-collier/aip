module Aip
  class Railtie < Rails::Railtie
    rake_tasks do
      # Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
      load File.join(File.dirname(__FILE__), 'tasks/aip/import.rake')
    end
  end
end
