require 'rails_helper'
require 'webmock'
require_relative '../support/validation_helper'

describe 'Homepage' do
  before :all do
    WebMock.enable!
    WebMock.stub_request(:get, 'https://public-api.wordpress.com/wp/v2/sites/americanarchivepb.wordpress.com/posts').to_return(body: File.read('spec/data/wpdatamock'))

    WebMock.stub_request(:get, 'http://wiki.americanarchive.org/').to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:get, 'http://fixit.americanarchive.org/?utm_campaign=fixit_from_website&utm_medium=website&utm_source=aapb_fixit_header').to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:get, 'http://fixit.americanarchive.org/?utm_campaign=help-us_from_website&utm_medium=website&utm_source=aapb_help-us_promo1').to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:get, 'http://fixitplus.americanarchive.org/?utm_campaign=help-us_from_website&utm_medium=website&utm_source=aapb_help-us_promo2').to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:get, 'https://www.zooniverse.org/projects/sroosa/roll-the-credits/?utm_campaign=help-us_from_website&utm_medium=website&utm_source=aapb_help-us_promo3').to_return(status: 200, body: '', headers: {})
    WebMock.stub_request(:get, 'https://www.instagram.com/amarchivepub/').to_return(status: 200, body: '', headers: {})

    WebMock.disable_net_connect!(allow_localhost: true)
  end

  it 'has expected content' do
    # WP-client gem must have hard coded reference to STDOUT or STDERR:
    # swapping $stdout and $stderr didn't quiet it.
    visit '/'
    expect(page.status_code).to eq(200)
    expect(page).to have_text('Discover historic programs')
    expect_fuzzy_xml(allow_default_title: true)
    expect(page).not_to have_css('input_search_q.q')
  end

  after :all do
    WebMock.disable!
  end
end
