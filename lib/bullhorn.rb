require 'net/http'
require 'uri'
require 'base64'
require 'json'
require 'cgi'

class Bullhorn
  VERSION = "0.0.1"

  URL = "http://bullhorn.it/api/v1/exception"

  FILTERING = %(['"]?\[?%s\]?['"]?=>?([^&\s]*))

  attr :filters
  attr :api_key
  attr :url
  
  def self.serialize(str)
    CGI.escape(Base64.encode64(str.to_json).strip)
  end

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

protected
  def notify(exception, env)
    Net::HTTP.post_form(URI(url), {
      :api_key      => api_key,
      :message      => exception.message,
      :backtrace    => serialize(exception.backtrace),
      :env          => serialize(whitelist(env)),
      :request_body => serialize(whitelist(request_body(env)))
    })
  end

  def request_body(env)
    if io = env['rack.input']
      io.rewind if io.respond_to?(:rewind)
      io.read
    end
  end
  
  def serialize(str)
    self.class.serialize(str)
  end
  
  def whitelist(str_or_hash)
    case str_or_hash
    when Hash
      str_or_hash.dup.tap do |h|
        h.keys.each do |key|
          h[key] = sanitize(h[key])  if h[key].respond_to?(:gsub)
        end
      end

    when String
      sanitize(str_or_hash)
    end
  end

  def sanitize(str)
    str.dup.tap do |ret|
      @filters.each do |filter|
        ret.gsub!(Regexp.new(FILTERING % filter)) { |m| 
          m.gsub($1, '[FILTERED]')
        }
      end
    end
  end
end
