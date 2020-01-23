class JimsController < ApplicationController
  def index
    # load my rekkids
    @special_collection = @special_collection = SpecialCollection.find_by_path('newshour')
    render 'jim'
  end
end
