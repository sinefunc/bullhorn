require 'helper'

class TestBullhorn < Test::Unit::TestCase
  setup do
    @app = lambda { |env| [200, { "Content-Type" => "text/plain" }, ["Hello"]] }
  end

  test "raises when no api_key" do
    assert_raise ArgumentError do
      Bullhorn.new(@app)
    end
  end

  test "accepts a filter of string arrays" do
    bullhorn = Bullhorn.new(@app, :api_key => "key", :filters => ['a', 'b'])
    assert_equal ['a', 'b'], bullhorn.filters
  end

  test "accepts a filter as a single string" do
    bullhorn = Bullhorn.new(@app, :api_key => "key", :filters => "password")
    assert_equal ['password'], bullhorn.filters
  end

  context "on raise" do
    Fail = Class.new(StandardError)

    setup do
      @fail = Fail.new("Fail!!!")
      @fail.stubs(:backtrace).returns(["line1", "line2"])
      @app = lambda { |env| raise @fail }

      @bullhorn = Bullhorn.new(@app, :api_key => "_key_",
                                     :url => "http://test.host/api/v1")
    end

    should "send a notification and raise the failure" do
      @bullhorn.expects(:notify)

      assert_raise Fail do
        @bullhorn.call({})
      end
    end

    should "send the proper request parameters" do
      uri = URI("http://test.host/api/v1")
      io  = stub("IO", :read => "FooBar")

      expected = {
        :api_key => '_key_',
        :message => 'Fail!!!',
        :backtrace => Bullhorn::Sender.serialize(['line1', 'line2']),
        :env => Bullhorn::Sender.serialize("params" => "a&b", "rack.input" => io.inspect),
        :request_body => Bullhorn::Sender.serialize("FooBar"),
        :sha1 => Digest::SHA1.hexdigest("Fail!!!" + ['line1', 'line2'].inspect)
      }

      Net::HTTP.expects(:post_form).with() { |u, hash|
        u == uri && hash == expected
      }

      begin
        @bullhorn.call({ "params" => "a&b", "rack.input" =>  io })
      rescue Fail
      end
    end
  end

  context "given filtering password / password_confirmation" do
    Fail = Class.new(StandardError)

    setup do
      @fail = Fail.new("Fail!!!")
      @fail.stubs(:backtrace).returns(["line1", "line2"])
      @app = lambda { |env| raise @fail }

      @bullhorn = Bullhorn.new(@app, :api_key => "_key_",
                                     :url => "http://test.host/api/v1",
                                     :filters => ["password"])
    end

    should "remove all traces of password param value in the env" do
      uri = URI("http://test.host/api/v1")
      io  = stub("IO", :read => "password=test&user[password]=test")

      expected = {
        :api_key => '_key_',
        :message => 'Fail!!!',
        :backtrace => Bullhorn::Sender.serialize(['line1', 'line2']),
        :env => Bullhorn::Sender.serialize("params" => "password=[FILTERED]&user[password]=[FILTERED]",
                                           "rack.input" => io.inspect),
        :request_body => Bullhorn::Sender.serialize("password=[FILTERED]&user[password]=[FILTERED]"),
        :sha1 => Digest::SHA1.hexdigest("Fail!!!" + ['line1', 'line2'].inspect)
      }

      Net::HTTP.expects(:post_form).with() { |u, hash|
        u == uri && hash == expected
      }

      begin
        @bullhorn.call("params" => "password=test&user[password]=test",
                       "rack.input" =>  io)
      rescue Fail
      end
    end
  end
end
