require_relative '../../scripts/ci/ci'
require 'tmpdir'

describe Ci do
  
  let(:credentials_path) {File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml'}
  let(:aapb_workspace_id) {'051303c1c1d24da7988128e6d2f56aa9'} # we make sure NOT to use this.
  
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
  
  it 'blocks some filetypes (small files)' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      ['js','html','rb'].each do |disallowed_ext|
        path = "#{dir}/file-name.#{disallowed_ext}"
        File.write(path, "content doesn't matter")
        expect{ci.upload(path, log_path)}.to raise_exception(/Upload failed/)
      end
      expect(File.read(log_path)).to eq('')
    end
  end
  
  it 'allows other filetypes (small files)' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      path = "#{dir}/small-file.txt"
      File.write(path, "content doesn't matter")
      expect{ci.upload(path, log_path)}.not_to raise_exception
      
      expect(list_names(ci).count).to eq(1)
      
      log_content = File.read(log_path)
      expect(log_content).to match(/^[^\t]+\tsmall-file\.txt\t[0-9a-f]{32}\n$/)
      id = log_content.strip.split("\t")[2]
      
      detail = ci.detail(id)
      expect([detail['name'],detail['id']]).to eq(['small-file.txt',id])
      
      ci.delete(id)
    end
    expect(list_names(ci).count).to eq(0)
  end
  
  it 'allows big files' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      path = "#{dir}/big-file.txt"
      big_file = File.open(path, 'a')
      (5*1024).times do |k|
        big_file.write("#{k}K"+'.'*1024+"\n")
      end
      big_file.flush
      expect(big_file.size).to be > (5*1024*1024)
      expect(big_file.size).to be < (6*1024*1024)
      expect{ci.upload(path, log_path)}.not_to raise_exception
      
      expect(list_names(ci).count).to eq(1)
      
      log_content = File.read(log_path)
      expect(log_content).to match(/^[^\t]+\tbig-file\.txt\t[0-9a-f]{32}\n$/)
      id = log_content.strip.split("\t")[2]
      
      detail = ci.detail(id)
      expect([detail['name'],detail['id']]).to eq(['big-file.txt',id])
      
      ci.delete(id)
    end
    expect(list_names(ci).count).to eq(0)
  end
  
  def get_ci
    workspace_id = YAML.load_file(credentials_path)['workspace_id']
    expect(workspace_id).to match(/^[0-9a-f]{32}$/)
    expect(workspace_id).not_to eq(aapb_workspace_id)
    ci = Ci.new({credentials_path: credentials_path})
    expect(ci.access_token).to match(/^[0-9a-f]{32}$/)
    list = list_names(ci)
    expect(list.count).to eq(0), "Expected workspace #{ci.workspace_id} to be empty, instead of #{list}"
    return ci
  end
  
  def list_names(ci)
    # TODO: Maybe this should be a real method on CiClient? Not sure.
    ci.list.map{|item| item['name']} - ['Workspace'] # A self reference is present even in an empty workspace.
  end

end
