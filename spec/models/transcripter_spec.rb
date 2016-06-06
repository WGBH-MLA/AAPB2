require_relative '../../app/models/transcripter'

describe Transcripter do
  it 'produces expected transcript' do
    srt = File.read('spec/fixtures/srt/1234.srt1.srt')
    html = Transcripter.from_srt(srt)
    expect(html).to eq(File.read('spec/fixtures/srt/1234.transcript.html'))
  end
end
