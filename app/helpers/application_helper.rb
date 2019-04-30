module ApplicationHelper
  def current_page(path)
    return 'current-page' if current_page?(path)
  end

  def clean_query_for_snippet(query)
    # remove stopwords from query
    stopwords = []
    File.read(Rails.root.join('jetty', 'solr', 'blacklight-core', 'conf', 'stopwords.txt')).each_line do |line|
      next if line.start_with?('#') || line.empty?
      stopwords << line.upcase.strip
    end

    query.upcase.gsub(/[[:punct:]]/, '').split.delete_if { |term| stopwords.include?(term) }
  end


  def get_last_day(month)
    if ['04','06','09','11'].include?(month)
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
    if date_val.match(/\A\d{4}\-\d{1,2}\-\d{1,2}\z/)

      year, month, day = date_val.scan(/\A(\d{4})\-(\d{1,2})\-(\d{1,2})\z/).flatten

    # 0000-00
    elsif date_val.match (/\A\d{4}\-\d{1,2}\z/)

      year, month = date_val.scan(/\A(\d{4})\-(\d{1,2})\z/).flatten

    # 0000
    elsif date_val.match (/\A\d{4}\z/)
     
      date_was_reset = true
      year = date_val
    end

    if !month || month == '00'
      date_was_reset = true
      
      if type == 'after'
        month = '01'
      else
        month = '12'
      end
    end

    # if we somehow got a 1999-00-31 or something, toss the day, cause that ain't real!
    if !day || day == '00'
      date_was_reset = true

      if type == 'after'
        day = '01'
      else
        day = get_last_day(month)
      end
    end

    proper_val = %(#{year}-#{month}-#{day})

    # ensure this record sorts after a real 12/31 record, when indexing only
    if type == 'index' && date_was_reset
      proper_val += " 23:59"
    end

    proper_val.to_time.strftime('%Y-%m-%dT%H:%M:%SZ')
  end
end
