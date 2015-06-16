require_relative '../../lib/html_scrubber'

describe HtmlScrubber do
  it 'scrubs "nbsp"' do
    expect(HtmlScrubber.scrub('debate Sunday evening.&nbsp; As&nbsp;Laura Weber reports'))
      .to eq 'debate Sunday evening. As Laura Weber reports'
  end
  it 'scrubs "quot"' do
    expect(HtmlScrubber.scrub('Edvard Grieg\'s &quot;Holberg Suite&quot;'))
      .to eq 'Edvard Grieg\'s "Holberg Suite"'
  end
  it 'scrubs backslash escapes and elements' do
    expect(HtmlScrubber.scrub(
      <<EOF
      <p>\\0x0AVPR covers the 2010 Winter Olympic Games from Vancouver.
      \\0x0A</p>\\0x0A<a href="http://www.vpr.net/news/olympics_2010/index.php">
      \\0x0A</a><div class="captioned_image_container">
EOF
        )).to eq 'VPR covers the 2010 Winter Olympic Games from Vancouver.'
  end
  it 'preserves linebreaks' do
    expect(HtmlScrubber.scrub(
      <<EOF
      <b>Town Meeting Related Stories</b> <p> <b><a href="/news_detail/76361/">
      School budget success could influence property tax reform </a><br /> 
      <a href="/news_detail/76358/">Waterbury rejects town, village merger</a>
EOF
        )).to eq [
          'Town Meeting Related Stories',
          'School budget success could influence property tax reform',
          'Waterbury rejects town, village merger'
        ].join("\n")
  
  end
  it 'tries to fix html with angle-brackets removed' do
    expect(HtmlScrubber.scrub(
      <<EOF
      em img style=margin-right: 10px float: left src=images/stories/earth.jpg 
      alt=earth width=250 height=90 Earth Edition /em focuses on diverse and 
      unique natural world of Southwest Florida. ... Produced from 2003 to 2006, 
      the programs received Emmy nominations and won Telly awards. 
      a http://video.wgcu.org/program/1354335502 img src=images/stories/watchbutton.gif 
      alt=watchbutton2 width=75 height=26 / /??/
EOF
        )).to eq [
          # TODO: Want this to be cleaner.
          'em img 10px float: left',
          'Earth Edition /em focuses on diverse and',
          'unique natural world of Southwest Florida. ... Produced from 2003 to 2006,',
          'the programs received Emmy nominations and won Telly awards.',
          'a http://video.wgcu.org img',
          '/ /??/'
        ].join("\n")
  end
  it 'handles capitalized tags' do
    expect(HtmlScrubber.scrub(
      <<EOF
      <P style='margin: 0in 0in 0pt'>A new report says Michigan's struggling economy
      is making the lives of the state's two-point-five million children more difficult.
      </P> <P style='margin: 0in 0in 0pt'><SPAN>&nbsp;&nbsp;</SPAN>
      Michigan Public Radio's Rachel Lippmann reports.</P>
EOF
        )).to eq [
          "A new report says Michigan's struggling economy",
          "is making the lives of the state's two-point-five million children more difficult.",
          "Michigan Public Radio's Rachel Lippmann reports."
        ].join("\n")
  end
end