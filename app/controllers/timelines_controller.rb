class TimelinesController < ApplicationController
  include PublicCache

  def eotp
    render 'timelines/index', layout: false
  end
end
