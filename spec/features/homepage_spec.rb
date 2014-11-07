require 'rails_helper'

describe "visiting homepage" do

  before :each do
    # TODO: ingest object
  end

  it "works" do
    visit '/'
    expect(page.status_code).to eq(200)
  end

end