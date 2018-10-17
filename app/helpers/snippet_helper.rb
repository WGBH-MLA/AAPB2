module SnippetHelper
  require 'action_view/helpers/text_helper'
  
  def snippet_from_query(query, text, snippet_length)
    include ActionView::TextHelper
    return nil unless text
    text_dictionary = text.upcase.gsub(/[[:punct:]]/, '').split

    intersection = query & text_dictionary
    return nil unless intersection && intersection.present?
    start = if (text.upcase.index(/\b(?:#{intersection[0]})\b/) - snippet_length) > 0
              text.upcase.index(/\b(?:#{intersection[0]})\b/) - snippet_length
            else
              0
            end

    body = '...' + text[start..-1].to_s + '...'
    highlight(body.truncate(snippet_length, separator: ' '), query)
  end
end