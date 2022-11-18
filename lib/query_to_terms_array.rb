class QueryToTermsArray
  attr_reader :query, :terms_array

  def initialize(query)
    @query = query
    return [] if !query || query.empty?
    query = query.upcase

    # if there are an even number of double quotes
    if query.count('"') % 2 == 0
      quotes = extract_quoted_phrases(query)

      quotes = quotes.map do |phrase|

        # Remove quotes from query
        query.remove!(phrase.first)

        # clean each phrase and split to arrary
        strip_punctuation(phrase.first).split(' ')
      end

      # Remove punctuation from unquoted bits
      unquotes = strip_punctuation(query).split(' ')

      # Remove any unquoted stopwords
      unquotes = remove_stopwords(unquotes).map { |term| [term.strip] }

      # return combined quotes and unquotes
      @terms_array = quotes + unquotes
    else
      # query has no quotes
      unquotes = strip_punctuation(query).split(' ').map { |term| [term.strip] }
      @terms_array = [unquotes - stopwords]
    end
  end

  private

  def stopwords
    Rails.cache.fetch('stopwords') do
      sw = File.readlines(Rails.root.join('jetty', 'solr', 'blacklight-core', 'conf', 'stopwords.txt'), chomp: true).map(&:upcase)
      sw.reject do |word|
        word =~ /^#/ || word.empty?
      end
    end
  end

  def remove_stopwords(terms_array)
    terms_array - stopwords
  end

  def extract_quoted_phrases(query)
    query.scan(/"([^"]*)"/)
  end

  def strip_punctuation(query)
    query.gsub(/[^\w\s]/, '')
  end
end

# And can be used in controllers like this...
# terms_array = QueryToTermsArray.new(query).term_array
