require_relative '../../lib/html_scrubber'

describe HtmlScrubber do
  it 'scrubs "nbsp"' do
    expect(HtmlScrubber.scrub('debate Sunday evening.&nbsp; As&nbsp;Laura Weber reports'))
      .to eq 'debate Sunday evening. As Laura Weber reports'
  end
end