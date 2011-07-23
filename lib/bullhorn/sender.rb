class Bullhorn
  module Sender
    extend self

    def serialize(str)
      Base64.encode64(str.to_json).strip
    end

    def notify(exception, env = {})
      bt = Backtrace.new(exception, :context => @show_code_context)

      Net::HTTP.post_form(URI(url), {
        :api_key      => api_key,
        :message      => exception.message,
        :backtrace    => serialize(bt.to_a),
        :env          => serialize(whitelist(env)),
        :request_body => serialize(whitelist(request_body(env))),
        :sha1         => sha1(exception),
        # APIv2
        :language       => Bullhorn::LANGUAGE,
        :client_name    => Bullhorn::CLIENT_NAME,
        :client_version => Bullhorn::VERSION,
        :url            => [ "http://", env['HTTP_HOST'], env['REQUEST_URI'] ].join(''),
        :class          => exception.class.to_s
      })
    end

  protected
    def sha1(exception)
      # Treat 2 exceptions as the same if they match the same exception class
      # and same origin.
      salt = '#bh#' + Bullhorn::CLIENT_NAME
      str  = [ salt, exception.class.to_s, exception.backtrace.first ].join('|')
      Digest::SHA1.hexdigest(str)
    end

    def request_body(env)
      if io = env['rack.input']
        io.rewind if io.respond_to?(:rewind)
        io.read
      end
    # TODO : only rescue the expected exceptions
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
