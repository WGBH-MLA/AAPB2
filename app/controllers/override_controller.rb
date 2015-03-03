class OverrideController < ApplicationController

  def show
    if params[:path] =~ /^[a-z0-9\/-]+$/i # paranoid about weird paths.
      override_file_path = "override/#{params[:path]}.html.erb"
      if File.exist?("app/views/#{override_file_path}")
        render file: override_file_path
        return
      end
    end
    fail ActionController::RoutingError.new('404')
  end

end
