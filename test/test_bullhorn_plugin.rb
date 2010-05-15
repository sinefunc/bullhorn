require "helper"
require "rack/test"

Bullhorn::Plugin.options = {
  :api_key => '_key_',
  :filters => 'password'
}

class RescueAction

protected
  def rescue_action_in_public(ex)
    raise ex
  end
end

class FakeRailsController < RescueAction
  Fail = Class.new(StandardError)

  include Bullhorn::Plugin

  attr :request

  def initialize(request, response)
    @request, @response = request, response
  end

  def index
    raise Fail, "Failure"
  rescue => ex
    rescue_action_in_public(ex)
  end
end

class TestBullhornPlugin < Test::Unit::TestCase
  def app
    @request = Rack::Request.new({})
    @app = FakeRailsController.new(@request, @response)
  end

  setup do
    FakeWeb.allow_net_connect = false
  end

  test "notifies on error" do
    FakeWeb.register_uri(:post, "http://bullhorn.it/api/v1/exception", :body => "OK")

    begin
      app.index
    rescue
    end
  end

  test "still raises original error" do
    FakeWeb.register_uri(:post, "http://bullhorn.it/api/v1/exception", :body => "OK")

    assert_raise FakeRailsController::Fail do
      app.index
    end
  end
end