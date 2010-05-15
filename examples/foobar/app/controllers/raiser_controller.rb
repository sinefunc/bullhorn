class RaiserController < ApplicationController
  include Bullhorn::Plugin

  def index
    raise "Error From Raiser"
  end
end