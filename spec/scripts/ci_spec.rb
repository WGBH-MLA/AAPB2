require_relative '../../scripts/ci/ci'
require 'tmpdir'

describe Ci, not_on_travis: true, slow: true do

  let(:credentials_path) {File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml'}
  let(:aapb_workspace_id) {'051303c1c1d24da7988128e6d2f56aa9'} # we make sure NOT to use this.

  it 'requires credentials' do
    expect { Ci.new }.to raise_exception('No credentials given')
  end

  it 'catches option typos' do
    expect { Ci.new({typo: 'should be caught'}) }.to raise_exception('Unrecognized options [:typo]')
  end

  it 'catches creditials specified both ways' do
    expect { Ci.new({credentials: {}, credentials_path: {}}) }.to raise_exception('Credentials specified twice')
  end

  it 'catches missing credentials' do
    expect { Ci.new({credentials: {}}) }.to raise_exception(
      'Expected ["client_id", "client_secret", "password", "username", "workspace_id"] in ci credentials, not []'
    )
  end

  it 'catches bad credentials' do
    bad_credentials = {
      'client_id' => 'bad',
      'client_secret' => 'bad',
      'password' => 'bad',
      'username' => 'bad',
      'workspace_id' => 'bad'
    }
    expect { Ci.new({credentials: bad_credentials}) }.to raise_exception('OAuth failed')
  end

  it 'blocks some filetypes (small files)' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      ['js','html','rb'].each do |disallowed_ext|
        path = "#{dir}/file-name.#{disallowed_ext}"
        File.write(path, "content doesn't matter")
        expect { ci.upload(path, log_path) }.to raise_exception(/Upload failed/)
      end
      expect(File.read(log_path)).to eq('')
    end
  end

  it 'allows other filetypes (small files)' do
    ci = get_ci
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      path = "#{dir}/small-file.txt"
      File.write(path, "lorem ipsum")
      expect_upload(ci, path, log_path)
    end
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
      expect_upload(ci, path, log_path)
    end
  end

  it 'enumerates' do
    ci = get_ci
    count = 6
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      count.times{ |i|
        path = "#{dir}/small-file-#{i}.mp4"
        File.write(path, "lorem ipsum #{i}")
        ci.upload(path, log_path)
      }
    end

    ids = ci.map{ |asset| asset['id']}
    expect(ids.count).to eq(count+1) # workspace itself is in list.
    ids.each{ |id| ci.delete(id)} # ci.each won't work, because you delete the data under your feet.
    expect(ci.map{ |asset| asset['id']}.count).to eq(1) # workspace can't be deleted.
  end

  def get_ci
    workspace_id = YAML.load_file(credentials_path)['workspace_id']
    expect(workspace_id).to match(/^[0-9a-f]{32}$/)
    expect(workspace_id).not_to eq(aapb_workspace_id)
    ci = Ci.new({credentials_path: credentials_path})
    expect(ci.access_token).to match(/^[0-9a-f]{32}$/)
    expect(ci.list_names.count).to eq(0),
      "Expected workspace #{ci.workspace_id} to be empty, instead of #{ci.list_names}"
    return ci
  end

  def expect_upload(ci, path, log_path)
    basename = File.basename(path)
    expect { ci.upload(path, log_path)}.not_to raise_exception

    expect(ci.list_names.count).to eq(1)

    log_content = File.read(log_path)
    expect(log_content).to match(/^[^\t]+\t#{basename}\t[0-9a-f]{32}\t\{[^\t]+\}\n$/)
    id = log_content.strip.split("\t")[2]

    detail = ci.detail(id)
    expect([detail['name'],detail['id']]).to eq([basename,id])

    before = Time.now
    download_url = ci.download(id)
    middle = Time.now
    download_url = ci.download(id)
    after = Time.now

    # make sure cache is working:
    expect(after-middle).to be < 0.01
    expect(middle-before).to be > 0.1 # Often greater than 1

    expect(download_url).to match(/^https:\/\/ci-buckets/)
    if File.new(path).size < 1024
      curl = Curl::Easy.http_get(download_url)
      curl.perform
      expect(curl.body_str).to eq(File.read(path)) # round trip!
    end

    ci.delete(id)
    expect(ci.detail(id)['isDeleted']).to eq(true)
    expect(ci.list_names.count).to eq(0)
  end

end
