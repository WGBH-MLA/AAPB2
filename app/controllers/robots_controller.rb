class RobotsController < ApplicationController
  REAL_HOST = 'americanarchive.org'
  def show
    respond_to do |format|
      format.txt do
        render text: if request.host == REAL_HOST
                       <<EOF
User-agent: *
Disallow: /catalog?
EOF
                     else
                       <<EOF
User-agent: *
Disallow: /
# Only #{REAL_HOST} should be indexed.
EOF
          end
      end
    end
  end
end
