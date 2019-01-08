module SnippetHelper
  def snippet_from_query(query, text, snippet_length, separator)
    return nil unless text
    # text = text.upcase.gsub(/[[:punct:]]/, '')
    text = text.upcase.gsub(/[^a-zA-z0-9\ \.\,:;!]/, '')
    text_dictionary = text.gsub(/[[:punct:]]/, '').split
    intersection = query & text_dictionary
    return nil unless intersection && intersection.present?
    intersection_index = text.index(/\b(?:#{intersection[0]})\b/)
    start = if intersection_index && (intersection_index - snippet_length) > 0
              intersection_index
            else
              0
            end

    body = '...' + text[start..-1].to_s + '...'
    ActionController::Base.helpers.highlight(body.truncate(snippet_length, separator: separator), query)
  end
end
