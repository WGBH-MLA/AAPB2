require 'curl'

describe 'CORS' do
  # There is advice on how to test this without a full server,
  # but since other tests require it, this is easier, and more robust.
  describe 'CORS disabled (default)' do
    it 'does not support CORS on arbitrary pages' do
      curl = Curl.get('http://localhost:3000')
      expect(curl.header_str).not_to match('Access-Control-Allow-Origin: *')
    end
    it 'does not support CORS on catalog pages' do
      curl = Curl.get('http://localhost:3000/catalog/1234')
      expect(curl.header_str).not_to match('Access-Control-Allow-Origin: *')
    end
  end
  describe 'CORS enabled' do
    def expect_cors(path)
      options_http = Curl.options('http://localhost:3000' + path) { |c| c.headers['Origin'] = '*' }
      expect(options_http.header_str).to match('Access-Control-Allow-Origin: *')

      get_http = Curl.get('http://localhost:3000' + path) { |c| c.headers['Origin'] = '*' }
      expect(get_http.header_str).to match('Access-Control-Allow-Origin: *')
    end
    it 'supports CORS on .pbcore' do
      expect_cors('/catalog/1234.pbcore')
    end
    %w(js xml).each do |format|
      it "supports CORS on .#{format}" do
        expect_cors("/api.#{format}?q=*:*&fl=id,title&rows=1")
      end
    end
  end
end
