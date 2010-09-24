class Bullhorn
  module Backtrace
    def initialize(exception)
      @exception = exception
      @raw       = exception.backtrace # Array
      # Sample:
      # [ "(irb):3:in `irb_binding'",
      #   "/Users/rsc/.rvm/rubies/ruby-1.9.2-p0/lib/ruby/1.9.1/irb/workspace.rb:80:in `eval'",
      #   "/Users/rsc/.rvm/rubies/ruby-1.9.2-p0/lib/ruby/1.9.1/irb/workspace.rb:80:in `evaluate'",
      #   "/Users/rsc/.rvm/rubies/ruby-1.9.2-p0/lib/ruby/1.9.1/irb/context.rb:254:in `evaluate'",
      #   "/Users/rsc/.rvm/rubies/ruby-1.9.2-p0/lib/ruby/1.9.1/irb.rb:159:in `block (2 levels) in eval_input'",
      #   "/Users/rsc/.rvm/rubies/ruby-1.9.2-p0/lib/ruby/1.9.1/irb.rb:273:in `signal_status'",
    end

    # Returns nil or an array.
    def get_context(fname, line, size = 2)
      begin
        from = [0, (line-size)].max
        File.open(fname, 'r') { |file| file.lines.to_a[from..(line+size)] }
      rescue
        nil
      end
    end

    def to_a
      @raw.inject([]) do |arr, line|
        m = line.match(/^(?<file>[^:]+):(?<line>[0-9]+):in `(?<function>.*)'$/)

        { :function => m[:function],
          :file     => m[:file],
          :line     => m[:line],
          :context  => get_context(m[:file], m[:line])
        }
      end
    end

    def to_json
      to_a.send(:to_json)
    end
  end
end
