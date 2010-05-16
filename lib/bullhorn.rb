require 'net/http'
require 'uri'
require 'base64'
require 'json'
require 'cgi'
require 'digest/sha1'

class Bullhorn
  autoload :Plugin, "bullhorn/plugin"
  autoload :Sender, "bullhorn/sender"

  VERSION = "0.0.2"

  URL = "http://bullhorn.it/api/v1/exception"

  FILTERING = %(['"]?\[?%s\]?['"]?=>?([^&\s]*))

  attr :filters
  attr :api_key
  attr :url

  include Sender

  def initialize(app, options = {})
    @app     = app
    @api_key = options[:api_key] || raise(ArgumentError, ":api_key is required")
    @filters = Array(options[:filters])
    @url     = options[:url] || URL
  end

  def call(env)
    status, headers, body =
      begin
        @app.call(env)
      rescue Exception => ex
        notify ex, env
        raise ex
      end

    [status, headers, body]
  end
end
