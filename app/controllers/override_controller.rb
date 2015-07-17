require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  PATH_PATTERN = /^[a-z0-9\/-]+$/
  def show
    if params[:path] =~ PATH_PATTERN # paranoid about weird paths.
      full_path = Rails.root + "app/views/#{params[:controller]}/#{params[:path]}.md"
      if File.exist?(full_path)
        params[:path] = nil # search widget grabs ALL parameters.
        set_view_fields(full_path)
        render file: "#{params[:controller]}/template.erb"
        return
      end
    end
    fail ActionController::RoutingError.new('404')
  end
  
  def set_view_fields(path)
    html = Markdowner.render_file(path)
    (@page_title, @body) = html.match(/^\s*<h1[^>]+>(.*?)<\/h1>(.*)/m).captures
  end
end