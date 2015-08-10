require 'rails_helper'
require_relative '../support/validation_helper'

describe 'Homepage' do
  it 'has expected content' do
    # WP-client gem must have hard coded reference to STDOUT or STDERR:
    # swapping $stdout and $stderr didn't quiet it.
    visit '/'

    expect(page.status_code).to eq(200)
    expect(page).to have_text('Discover historic programs')
    # Check for access type constraints:
    expect(page).to have_link('Debate', 
      href: "/catalog?f%5Baccess_types%5D%5B%5D=#{PBCore::PUBLIC_ACCESS}&f%5Bgenres%5D%5B%5D=Debate")
    expect(page).to have_link('Health', 
      href: "/catalog?f%5Baccess_types%5D%5B%5D=#{PBCore::PUBLIC_ACCESS}&f%5Btopics%5D%5B%5D=Health")
    expect_fuzzy_xml(allow_default_title: true)
  end
end
