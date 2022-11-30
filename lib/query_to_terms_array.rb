# Build an array of terms from a search query
#
# Capitalize all terms
# Extract quoted phrases
# Strip punctuation from unquoted phrases
# Remove stopwords
#
#
# @example
# the french chef with Julia Child -> [["FRENCH"], ["CHEF"], ["JULIA"], ["CHILD"]]
# "the french chef" with Julia Child -> [["THE", "FRENCH", "CHEF"], ["JULIA"], ["CHILD"]]

class QueryToTermsArray
  # @param [String] query The search query
  #
  # @return [Array<terms_array>] Returns an array of phrases, where each phrase is an array of terms in that phrase.
  attr_reader :query

  def initialize(query)
    raise ArgumentError, "expected query to not be empty" if query.to_s.empty?
    @query = query.to_s.upcase
  end

  def terms_array
    quoted_terms_arrays + unquoted_terms_arrays
  end

  private

  # Get cached list of stopwords from stopwords.txt
  # @return [Array<String>] array of stopwords
  def stopwords
    Rails.cache.fetch('stopwords') do
      sw = File.readlines(Rails.root.join('jetty', 'solr', 'blacklight-core', 'conf', 'stopwords.txt'), chomp: true).map(&:upcase)

      # Remove comments and empty lines
      sw.reject do |word|
        word =~ /^#/ || word.empty?
      end
    end
  end

  # @return [Array<String>] double-quoted phrases from #query.
  def quoted_phrases
    query.
      # Match any double quoted phrase and capturing the stuff in between,
      scan(/"([^"]*)"/).
      # and grab the first (and only) thing captured.
      map(&:first)
  end

  # @param [String]
  # @return [String] the original string minus all non-alphanumeric, non-space
  #   characters, and all repeated whitespace collapsed into single space, and
  #   whitespace stripped from front and back.
  def strip_special_chars(str)
    str.
      # Replace any non-alphanumeric, non-space character with a single space,
      gsub(/[^[:alpha:] ]/, ' ').
      # and collapse multiple whitespace down to single space,
      gsub(/\s+/, ' ').
      # and strip whitespace off front and back of string.
      strip
  end

  # @return [Array<Array>] array of single-element arrays, each of which contain
  #   a single term from #unquoted_terms.
  def unquoted_terms_arrays
    unquoted_terms.map { |term| Array(term) }
  end

  # @return [Array] all terms from the original query that are not contained
  # within double quotes.
  def unquoted_terms
    strip_special_chars(unquoted_query).split - stopwords
  end

  # @return [String] the original query minus any double-quoted phrases.
  def unquoted_query
    query_copy = query.dup
    quoted_phrases.each do |quoted_phrase|
      query_copy.remove!(quoted_phrase)
    end
    query_copy
  end

  # @return [Array<Array>] list of double-quoted phrases where each phrase has
  #   been converted into an array of terms.
  def quoted_terms_arrays
    quoted_phrases.map do |quoted_phrase|
      strip_special_chars(quoted_phrase).split
    end
  end
end
