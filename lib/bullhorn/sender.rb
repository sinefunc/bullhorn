class Bullhorn
  module Sender
    extend self

    def serialize(str)
      str # CGI.escape(Base64.encode64(str.to_json).strip)
    end

    def notify(exception, env)
      Net::HTTP.post_form(URI(url), {
        :api_key      => api_key,
        :message      => exception.message,
        :backtrace    => serialize(exception.backtrace),
        :env          => serialize(whitelist(env)),
        :request_body => serialize(whitelist(request_body(env)))
      })
    end
  
  protected
    def request_body(env)
      if io = env['rack.input']
        io.rewind if io.respond_to?(:rewind)
        io.read
      end
    rescue
      ""
    end
    
    def whitelist(str_or_hash)
      case str_or_hash
      when Hash
        str_or_hash.dup.tap do |h|
          h.keys.each do |key|
            if h[key].respond_to?(:gsub)
              h[key] = sanitize(h[key])
            else
              h[key] = h[key].inspect
            end
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
end
