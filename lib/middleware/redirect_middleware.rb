# http://blog.dynamic50.com/2011/02/22/redirect-all-requests-for-www-to-root-domain-with-heroku/

class RedirectMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    if request.host.starts_with?('www.')
      [301, { 'Location' => request.url.sub('//www.', '//') }, self]
    elsif request.host.ends_with?('americanarchiveinventory.org')
      [301, { 'Location' => 'http://americanarchive.org' }, self]
    else
      @app.call(env)
    end
  end

  def each(&_block)
  end
end
