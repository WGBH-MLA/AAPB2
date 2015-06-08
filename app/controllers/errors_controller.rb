class ErrorsController < ApplicationController
 
  def show
    render status_code.to_s, status: status_code
  end
 
protected
 
  def status_code
    params[:status_code] || 500
  end
 
end