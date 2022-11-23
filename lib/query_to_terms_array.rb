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
  attr_reader :query, :terms_array

  def initialize(query)
    @query = query
    return [] if !query || query.empty?
    query = query.upcase

    # if there are an even number of double quotes
    if query.count('"').even?
      quotes = extract_quoted_phrases(query)

      quotes.map! do |phrase|
        # Remove quotes from query
        query.remove!(phrase.first)

        # split each phrase to word arrary
        phrase.first.split
      end

      # Remove punctuation from unquoted bits
      unquotes = strip_punctuation(query).split

      # Remove any unquoted stopwords and convert to term array
      unquotes = remove_stopwords(unquotes).map { |term| [term] }

      # return combined quotes and unquotes
      @terms_array = quotes + unquotes
    else
      # query has no quotes. Clean and split
      unquotes = strip_punctuation(query).split

      # Remove stopwords and convert to term array
      @terms_array = remove_stopwords(unquotes).map { |term| [term] }

    end
  end

  private

  # Get cached list of stopwords from stopwords.txt
  # @return [Array<String>] Returns array of stopwords
  def stopwords
    Rails.cache.fetch('stopwords') do
      sw = File.readlines(Rails.root.join('jetty', 'solr', 'blacklight-core', 'conf', 'stopwords.txt'), chomp: true).map(&:upcase)

      # Remove comments and empty lines
      sw.reject do |word|
        word =~ /^#/ || word.empty?
      end
    end
  end

  # Given an array of words, return the array without any stopwords
  # @param [Array<String>] terms_array A word array from the query
  def remove_stopwords(terms_array)
    terms_array - stopwords
  end

  # Given a query string, return an array of quoted phrases in that string
  # @param [String] query The search query
  def extract_quoted_phrases(query)
    # Match any double quote followed by 0 or more non double quote characters, followed by a double quote.
    # This matches multiple sets of quoted phrases
    query.scan(/"([^"]*)"/)
  end

  # Given a query string, return the string without punctuation
  def strip_punctuation(query)
    # Removes any non alphanumeric or space character
    query.gsub(/[^[:alpha:] ]/, '')
  end
end
