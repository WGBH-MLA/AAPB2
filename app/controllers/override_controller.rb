require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  PATH_PATTERN = /^[a-z0-9\/-]+$/
  def show
    if params[:path] =~ PATH_PATTERN # paranoid about weird paths.
#      override_html_erb_file_path = "override/#{params[:path]}.html.erb"
#      if File.exist?("app/views/#{override_html_erb_file_path}")
#        render file: override_html_erb_file_path
#        return
#      end
      full_path = Rails.root + "app/views/override/#{params[:path]}.md"
      if File.exist?(full_path)
        html = Markdowner.render_file(full_path)
        (@title, @body) = html.match(/^\s*<h1[^>]*>(.*?)<\/h1>(.*)/m).captures
        # This is wrong, but not worth a full xml parse.
        @page_title = @title
        params[:path] = nil # search widget grabs ALL parameters.
        render file: 'override-containers/md_container.erb'
        return
      end
    end
    fail ActionController::RoutingError.new('404')
  end
end
