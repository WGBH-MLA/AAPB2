module ApplicationHelper
  def current_page(path)
    return 'current-page' if current_page?(path)
  end
end
