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
      <<-EOF
      <p>\\0x0AVPR covers the 2010 Winter Olympic Games from Vancouver.
      \\0x0A</p>\\0x0A<a href="http://www.vpr.net/news/olympics_2010/index.php">
      \\0x0A</a><div class="captioned_image_container">
      EOF
        )).to eq 'VPR covers the 2010 Winter Olympic Games from Vancouver.'
  end
  it 'preserves linebreaks' do
    expect(HtmlScrubber.scrub(
      <<-EOF
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
      <<-EOF
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
      <<-EOF
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
  xit '....?' do
    expect(HtmlScrubber.scrub(
      <<-EOF
      a http://www.pbs.org/wnet/need-to-know/ target=_blank;span style=font-size: 12pt;;em;Need to 
      Know/em/ ;img style=margin-right: 10px; float: left; src=images/stories/tv/needtoknow.png 
      alt=needtoknow width=250 height=90 ; Need to Know is the PBS TV- and web- newsmagazine 
      that gives you what you need to know along with a healthy dose of insight, perspective 
      and wit. 
      EOF
        )).to eq []
  end
  it 'handles MS Word XML' do
    expect(HtmlScrubber.scrub(
      <<-EOF
      <p> Congressman Peter Welch is pushing for new legislation to support businesses that hire unemployed veterans. </p>
      <!--[if gte mso 9]><xml> <w:WordDocument> <w:View>Normal</w:View> <w:Zoom>0</w:Zoom> 
      <w:Compatibility> <w:BreakWrappedTables/> <w:SnapToGridInCell/> <w:WrapTextWithPunct/> 
      <w:UseAsianBreakRules/> </w:Compatibility> <w:BrowserLevel>MicrosoftInternetExplorer4</w:BrowserLevel> 
      </w:WordDocument> </xml><![endif]--><!--[if gte mso 10]> <style> /* Style Definitions */ 
      table.MsoNormalTable {mso-style-name:"Table Normal"; mso-tstyle-rowband-size:0; mso-tstyle-colband-size:0; mso-style-noshow:yes; mso-style-parent:""; mso-padding-alt:0in 5.4pt 0in 5.4pt; mso-para-margin:0in; mso-para-margin-bottom:.0001pt; mso-pagination:widow-orphan; font-size:10.0pt; font-family:"Times New Roman";} 
      </style> <![endif]--><!--[if gte mso 9]><xml> <o:shapedefaults v:ext="edit" spidmax="1026"/> </xml><![endif]-->
      <!--[if gte mso 9]><xml> <o:shapelayout v:ext="edit"> <o:idmap v:ext="edit" data="1"/> </o:shapelayout></xml><![endif]--> 
      <p> (Host) Vermont veterans who've returned from deployment to Afghanistan only to find the job market scarce would get a leg up on finding work under a bill sponsored by Congressman Peter Welch.
      <style attr='value'>mock</style>
      EOF
        )).to eq [
          'Congressman Peter Welch is pushing for new legislation to support businesses that hire unemployed veterans.',
          '(Host) Vermont veterans who\'ve returned from deployment to Afghanistan only to find the job market scarce would get a leg up on finding work under a bill sponsored by Congressman Peter Welch.'
        ].join("\n")
  end
end