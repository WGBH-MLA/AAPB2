require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../../scripts/ci/ci'
require 'tmpdir'

describe 'Media', not_on_travis: true do

  TARGET = 'lorem ipsum'

  def safe_ci
    credentials_path = File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml'
    ci = Ci.new({credentials_path: credentials_path})
    fail 'Workspace must be empty' unless ci.list_names.empty?
    ci
  end

  def setup(ci)
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      path = "#{dir}/small-file.txt"
      File.write(path, TARGET)
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
    ci = safe_ci
    ci_id = setup(ci)

    # Capybara won't let us follow remote redirects:
    # It tries to look for a route based on the remote path.
    #
    # visit '/media/1234'
    # expect(page).to have_text(TARGET)

    curl = Curl::Easy.http_get('http://localhost:3000/media/1234')
    curl.follow_location = true
    curl.perform
    expect(curl.body_str).to eq(TARGET)

    ci.delete(ci_id)
  end

end
