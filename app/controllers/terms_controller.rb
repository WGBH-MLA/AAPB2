class TermsController < ApplicationController
  def show
    render 'show'
  end
  
  def create
    # Right now, the form submit by itself is sufficient.
    session[:affirm_terms] = true
    redirect_to "/catalog/#{CGI::escape(params['id'])}"
  end
end
