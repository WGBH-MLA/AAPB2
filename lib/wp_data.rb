class WPData
  def data(num = 1)
    @data ||= format_posts(fetch, num)
  end

  def fetch
    return Curl.get('https://public-api.wordpress.com/wp/v2/sites/americanarchivepb.wordpress.com/posts').body
  rescue Curl::Err => e
    puts e.inspect
    logger.error "failed to receive wp data. dangit! #{e.backtrace}"
    ''
  end

  def format_posts(resp_body, num)
    posts = JSON.parse(resp_body)
    Array.new(num) do |n|
      { link: posts[n]['link'], title: posts[n]['title']['rendered'], content: posts[n]['content']['rendered'] }
    end
  end
end
