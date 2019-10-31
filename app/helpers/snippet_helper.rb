module SnippetHelper
  def snippet_from_query(query, text, snippet_length, separator)
    return nil unless text
    # text = text.upcase.gsub(/[[:punct:]]/, '')
    text = text.upcase.gsub(/[^a-zA-z0-9\ \.\,:;!]/, '')
    term_hits = []

    query.each do |term|
      if term.split.length > 1
        body = process_compound_query_terms(term, text, snippet_length)
        term_hits << body unless body.nil?
      else
        body = process_single_query_terms(query, text, snippet_length)
        term_hits << body unless body.nil?
      end
    end

    ActionController::Base.helpers.highlight(term_hits[0].truncate(snippet_length, separator: separator), query) unless term_hits.empty?
  end

  private

  def process_single_query_terms(query, text, snippet_length)
    text_dictionary = text.gsub(/[[:punct:]]/, '').split
    intersection = query & text_dictionary
    return nil unless intersection && intersection.present?
    intersection_index = text.index(/\b(?:#{intersection[0]})\b/)
    start = if intersection_index && (intersection_index - snippet_length) > 0
              intersection_index
            else
              0
            end
    '...' + text[start..-1].to_s + '...'
  end

  def process_compound_query_terms(term, text, snippet_length)
    return nil unless text.include?(term)
    term_index = text.index(term)
    start = if term_index && (term_index - snippet_length) > 0
              term_index
            else
              0
            end
    '...' + text[start..-1].to_s + '...'
  end
end
