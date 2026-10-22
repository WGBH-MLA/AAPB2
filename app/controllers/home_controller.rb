require_relative '../models/featured'
require 'wp_data'

class HomeController < ApplicationController
  include PublicCache

  def show
    render 'show'
  end
end
