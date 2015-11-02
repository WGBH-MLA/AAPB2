class TermsController < ApplicationController
  def show
    @terms = Override.find_by_path('legal/orr-rules')
    render 'show'
  end

  def create
    # Right now, the form submit by itself is sufficient.
    session[:affirm_terms] = true
    redirect_to(target + CGI.escape(params['id']))
  end
  
  def target
    '/catalog/'
  end
end
