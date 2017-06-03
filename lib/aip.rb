require 'aip/version'
require 'aip/railtie' if defined?(Rails)
require 'aip/log'

module Aip
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :Configuration
  end

  # @api public
  #
  # Exposes the Packager configuration
  #
  # @yield [Packager::Configuration] if a block is passed
  # @return [Packager::Configuration]
  # @see Aip::Configuration for configuration options
  def self.config(&block)
    @config ||= Aip::Configuration.new

    yield @config if block

    @config
  end
end
