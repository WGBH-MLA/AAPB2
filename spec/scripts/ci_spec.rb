require_relative '../../scripts/ci/ci'

describe Ci do
  
  let(:credentials_path) {File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml'}
  
  it 'requires credentials' do
    expect{Ci.new}.to raise_exception('No credentials given')
  end
  
  it 'catches option typos' do
    expect{Ci.new({typo: 'should be caught'})}.to raise_exception('Unrecognized options [:typo]')
  end
  
  it 'catches creditials specified both ways' do
    expect{Ci.new({credentials: {}, credentials_path: {}})}.to raise_exception('Credentials specified twice')
  end
  
  it 'catches missing credentials' do
    expect{Ci.new({credentials: {}})}.to raise_exception(
      'Expected ["client_id", "client_secret", "password", "username", "workspace_id"] in ci credentials, not []'
    )
  end
  
  it 'connects successfully' do
    expect_scratch_workspace
    expect(Ci.new({credentials_path: credentials_path}).access_token).to match(/[0-9a-f]{32}/)
  end
  
  def expect_scratch_workspace
    expect(YAML.load_file(credentials_path)).not_to eq('051303c1c1d24da7988128e6d2f56aa9')
  end

end
