require_relative '../models/featured'
require 'wp_data'

class HomeController < ApplicationController
  def show
    render 'show'
  end
end
