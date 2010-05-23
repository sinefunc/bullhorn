$:.unshift File.expand_path("../../bullhorn/lib")

require 'rubygems'
require 'sinatra'
require 'bullhorn'

enable :raise_errors
use Bullhorn, :api_key => "__sample_api_key__"

get '/fail' do
  raise 'Hello'
end
