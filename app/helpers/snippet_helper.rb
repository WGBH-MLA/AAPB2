module SnippetHelper
  def snippet_from_query(query, text, snippet_length, separator)
    return nil unless text
    text_dictionary = text.upcase.gsub(/[[:punct:]]/, '').split

    intersection = query & text_dictionary
    return nil unless intersection && intersection.present?
    start = if (text.upcase.index(/\b(?:#{intersection[0]})\b/) - snippet_length) > 0
              text.upcase.index(/\b(?:#{intersection[0]})\b/)
            else
              0
            end

    body = '...' + text[start..-1].to_s + '...'
    ActionController::Base.helpers.highlight(body.truncate(snippet_length, separator: separator), query)
  end
end
