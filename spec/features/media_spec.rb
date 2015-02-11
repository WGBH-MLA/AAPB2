require 'rails_helper'
require_relative '../../scripts/pb_core_ingester'
require_relative '../../scripts/ci/ci'

describe 'Media', not_on_travis: true do
  
  def get_ci
    credentials_path = File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml'
    ci = Ci.new({credentials_path: credentials_path})
    raise "Workspace must be empty" unless ci.list_names.empty?
    ci
  end
  
  def setup(ci)
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      path = "#{dir}/small-file.txt"
      File.write(path, "lorem ipsum")
      ci_id = ci.upload(path, log_path)

      pbcore = File.read('spec/fixtures/pbcore/clean-MOCK.xml')
      pbcore.gsub!('1234</pbcoreIdentifier>',
        "1234</pbcoreIdentifier><pbcoreIdentifier source='Sony Ci'>#{ci_id}</pbcoreIdentifier>")

      ingester = PBCoreIngester.new
      ingester.delete_all
      ingester.ingest_xml(pbcore)
      ci_id
    end
  end
  
  it 'works' do
    ci = get_ci
    ci_id = setup(ci)
    
    visit '/media/1234'
    expect(page.status_code).to eq(200) # TODO: should redirect
    expect(page).to have_text('https://ci-buckets-assets') 
    
    ci.delete(ci_id)
  end
  
end