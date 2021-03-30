class TimelinesController < ApplicationController
  def eotp
    render 'timelines/index', layout: false
  end
end
