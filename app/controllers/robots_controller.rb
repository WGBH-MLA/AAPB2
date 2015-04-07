class RobotsController < ApplicationController
  REAL_HOST = 'americanarchive.org'
  def show
    respond_to do |format|
      format.txt do
        render text: if request.host == REAL_HOST
            "User-agent: *\nDisallow: /catalog?"
          else
            "User-agent: *\nDisallow: /\n# Only #{REAL_HOST} should be indexed."
          end
      end
    end
  end
end