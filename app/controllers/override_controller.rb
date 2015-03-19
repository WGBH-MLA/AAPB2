require_relative '../../lib/markdown'

class OverrideController < ApplicationController
  def show
    if params[:path] =~ /^[a-z0-9\/-]+$/i # paranoid about weird paths.
#      override_html_erb_file_path = "override/#{params[:path]}.html.erb"
#      if File.exist?("app/views/#{override_html_erb_file_path}")
#        render file: override_html_erb_file_path
#        return
#      end
      override_md_file_path = "override/#{params[:path]}.md"
      full_path = (File.dirname(File.dirname(__FILE__))) + "/views/#{override_md_file_path}"
      if File.exist?(full_path)
        html = Markdown.render_file(full_path)
        (@title, @body) = html.match(%r{^\s*(<h1>.*?<\/h1>)(.*)}m).captures
        # This is wrong, but not worth a full xml parse.
        render file: 'override-containers/md-container.erb'
        return
      end
    end
    fail ActionController::RoutingError.new('404')
  end
end
