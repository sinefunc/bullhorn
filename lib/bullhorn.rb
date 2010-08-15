require 'net/http'
require 'uri'
require 'base64'
require 'json'
require 'cgi'
require 'digest/sha1'

class Bullhorn
  autoload :Plugin, "bullhorn/plugin"
  autoload :Sender, "bullhorn/sender"

  VERSION = "0.0.5"

  URL = "http://www.bullhorn.it/api/v1/exception"

  FILTERING = %(['"]?\[?%s\]?['"]?=>?([^&\s]*))

  attr :filters
  attr :api_key
  attr :url
  attr :ignore_exceptions

  include Sender

  def initialize(app, options = {})
    @app               = app
    @api_key           = options[:api_key] || raise(ArgumentError, ":api_key is required")
    @filters           = Array(options[:filters])
    @url               = options[:url] || URL
    @ignore_exceptions = Array(options[:ignore_exceptions] || default_ignore_exceptions)
  end

  def call(env)
    status, headers, body =
      begin
        @app.call(env)
      rescue Exception => ex
        unless ignore_exceptions.include?(ex.class)
          notify ex, env
        end

        raise ex
      end

    [status, headers, body]
  end

protected
  def default_ignore_exceptions
    [].tap do |exceptions|
      exceptions << ActiveRecord::RecordNotFound if defined? ActiveRecord
      exceptions << AbstractController::ActionNotFound if defined? AbstractController
      exceptions << ActionController::RoutingError if defined? ActionController
    end
  end
end
