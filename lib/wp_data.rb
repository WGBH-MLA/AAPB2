class WPData
  def data(num = 1)
    @data ||= format_posts(fetch, num)
  end

  def fetch
    Curl.get('https://public-api.wordpress.com/wp/v2/sites/americanarchivepb.wordpress.com/posts').body
  rescue Curl::Err::GotNothingError, Curl::Err::RecvError => e
    default_post
  end

  def format_posts(resp_body, num)
    begin
      posts = JSON.parse(resp_body)
    rescue JSON::ParserError
      posts = JSON.parse(default_post)
    end
    
    Array.new(num) do |n|
      { link: posts[n]['link'], title: posts[n]['title']['rendered'], content: posts[n]['content']['rendered'] }
    end
  end

  def default_post
    File.read('spec/data/wpdatamock')
  end
end
