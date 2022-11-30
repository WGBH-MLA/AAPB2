# Service class for converting a text query into a specially formatted array
# of terms to be used in highlighting text in transcript snippets.
#
# The class converts a text query into an array of terms according to the
# following rules:
# * Query terms not in double quotes are put into single-element arrays.
# * Query terms within double quotes are put into an array where each element
#   is a term within the double-quoted phrase.
# * Stopwords are not removed from double-quoted phrases.
# * Stopwords are removed from unquoted query terms.
# * Special characters, in this case any non-alphanumeric, non-space character
#   is removed.
#
# @see ./spec/lib/query_to_terms_array_spec.rb
# @see SnippetHelper::Snippet - class that uses output from
#   QueryToTermsArray#terms_array
#
# @example
# query = "the french chef with Julia Child"
# QueryToTermsArray.new(query).terms_array
# => [["FRENCH"], ["CHEF"], ["JULIA"], ["CHILD"]]
#
# query = '"the french chef" with Julia Child'
# QueryToTermsArray.new(query).terms_array
# => [["THE", "FRENCH", "CHEF"], ["JULIA"], ["CHILD"]]
class QueryToTermsArray
  attr_reader :query

  # @param [String] query The search query
  def initialize(query)
    @query = query.to_s.upcase
  end

  # @return [Array<Array>] array where the first elements are arrays containing
  #   each term from a quoted phrase, including stopwords, but excluding special
  #   characters, followed by each unquoted term in the query, excluding both
  #   stopwords and special chars.
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
