module ApplicationHelper
  def current_page(path)
    return 'current-page' if current_page?(path)
  end

  def convert_timestamp_to_seconds(timestamp)
    dt = DateTime.parse(timestamp)
    dt.hour * 3600 + dt.min * 60 + dt.sec
  rescue
    nil
  end

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
    query.gsub(/[[:punct:]]/, '')
  end

  def query_to_terms_array(query)
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
      unquotes = strip_punctuation(query).split(' ').map { |term| [term.strip] }

      # Remove any unquoted stopwords
      unquotes = remove_stopwords(unquotes)

      # return combined quotes and unquotes
      terms_array = quotes + unquotes
    else
      # query has no quotes
      unquotes = strip_punctuation(query).split(' ').map { |term| [term.strip] }
      terms_array = [unquotes - stopwords]
    end
  end

  def get_last_day(month)
    if %w(04 06 09 11).include?(month)
      '30'
    elsif month == '02'
      '28'
    else
      '31'
    end
  end

  def handle_date_string(date_val, type)
    # type => before, after, index
    # 0000-00-00
    if /\A\d{4}\-\d{1,2}\-\d{1,2}\z/ =~ date_val
      year, month, day = date_val.scan(/\A(\d{4})\-(\d{1,2})\-(\d{1,2})\z/).flatten

      # 0000-00
    elsif /\A\d{4}\-\d{1,2}\z/ =~ date_val
      year, month = date_val.scan(/\A(\d{4})\-(\d{1,2})\z/).flatten

      # 0000
    elsif /\A\d{4}\z/ =~ date_val
      date_was_reset = true
      year = date_val
    end

    if !month || month == '00'
      date_was_reset = true
      month = type == 'after' ? '01' : '12'
    end

    # if we somehow got a 1999-00-31 or something, toss the day, cause that ain't real!
    if !day || day == '00'
      date_was_reset = true
      day = type == 'after' ? '01' : get_last_day(month)
    end

    proper_val = %(#{year}-#{month}-#{day})

    # ensure this record sorts after a real 12/31 record, when indexing only
    proper_val += ' 23:59' if type == 'index' && date_was_reset

    proper_val.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
  end
end
