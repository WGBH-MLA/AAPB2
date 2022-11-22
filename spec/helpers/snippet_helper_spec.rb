require 'rails_helper'
require 'webmock'
require 'json'
include ApplicationHelper
include SnippetHelper

describe SnippetHelper do
  before :all do
    # WebMock is disabled by default, but we use it for these tests.
    # Note that it is re-disabled in an :after hook below.
    WebMock.enable!
  end

  json_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json'
  let(:json_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json') }
  let(:json_transcript) { TranscriptFile.new("cpb-aacip-111-21ghx7d6", json_url) }

  txt_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-507-0000000j8w/cpb-aacip-507-0000000j8w-transcript.txt'
  let(:txt_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-507-0000000j8w-transcript.txt') }
  let(:txt_transcript) { TranscriptFile.new("cpb-aacip-507-0000000j8w", txt_url) }

  # queries are split up into no-stopword arrays in appl helper
  let(:transcript_query_1) { [["ARKANSAS"]] }
  let(:transcript_query_2) { [%w(SENATOR PRYOR)] }
  let(:transcript_query_3) { [%w(FILED FOR A DELAY), %w(NEVER GONNA GET MATCHED)] }
  let(:transcript_query_4) { [%w(TWO DOZEN FINE POTENTIAL NOMINEES FOR THE POSITION OF SECRETARY OF THE INTERIOR)] }

  let(:srt_example) { File.read('./spec/fixtures/captions/srt/srt_example.srt') }
  let(:caption_file) { CaptionFile.new("1a2b", "srt") }

  # single
  let(:transcript_snippet_1) { TimecodeSnippet.new('cpb-aacip-111-21ghx7d6', transcript_query_1, json_transcript.plaintext, JSON.parse(json_transcript.file_content)["parts"]) }
  # compound
  let(:transcript_snippet_2) { TimecodeSnippet.new('cpb-aacip-111-21ghx7d6', transcript_query_2, json_transcript.plaintext, JSON.parse(json_transcript.file_content)["parts"]) }
  # caption
  let(:caption_snippet1) { Snippet.new('cpb-aacip-111-21ghx7d6', transcript_query_3, caption_file.text) }
  # txt
  let(:transcript_snippet_4) { Snippet.new('cpb-aacip-507-0000000j8w', transcript_query_4, txt_transcript.plaintext) }

  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/transcripts/ with the same filename they have in S3.
    WebMock.stub_request(:head, json_url).to_return(status: 200)
    WebMock.stub_request(:head, txt_url).to_return(status: 200)
    WebMock.stub_request(:get, json_url).to_return(body: json_example)
    WebMock.stub_request(:get, txt_url).to_return(body: txt_example)

    CaptionFile.any_instance.stub(:captions_src).and_return('https://s3.amazonaws.com/americanarchive.org/captions/1a2b.srt')
    WebMock.stub_request(:get, caption_file.captions_src).to_return(body: srt_example)
    WebMock.stub_request(:head, caption_file.captions_src).to_return(status: 200)
  end

  describe '#new' do
    it 'initializes with the expected attrs' do
      expect(transcript_snippet_1.snippet).to eq(" FOR THIS 15TH ANNIVERSARY CELEBRATION AND DEDICATION CEREMONY IS MR GEORGE CAMPBELL CHAIRMAN OF THE <mark>ARKANSAS</mark> EDUCATIONAL TELEVISION COMMISSION GOOD AFTERNOON DISTINGUISHED GUESTS LADIES AND GENTLEMEN ")
      expect(transcript_snippet_1.match_timecode).to eq("50.24")
    end

    it 'initializes with expected attrs for compound query' do
      expect(transcript_snippet_2.snippet).to eq(" NOW I MAKE NO APOLOGIES FOR STORIES I MAY OR MAY NOT TALE CAN CERTAINLY RAISE BUT I JUST CANT THINK <mark>SENATOR PRYOR</mark> ALL TALKING ABOUT LEE REEVES FROM A PARTICULARLY GOVERNMENTAL AND STATE GOVERNMENT")
      expect(transcript_snippet_2.match_timecode).to eq("2061.79")
    end

    it 'initializes with expected attrs for caption file' do
      expect(caption_snippet1.snippet).to eq(" THE SUMMER OF 1958 THAT ALLOWED THE LOST YEAR TO HAPPEN THE FIRST ONE WAS THAT THE SCHOOL BOARD HAD <mark>FILED FOR A DELAY</mark>  A NUMBER OF BUSINESS LEADERS PERSUADED A MAJORITY OF THE MEMBERS OF THE SCHOOL")
    end

    it 'initializes with expected attrs for txt file' do
      expect(transcript_snippet_4.snippet).to eq("AT THE OLD EXECUTIVE OFFICE BUILDING PRES RONALD REAGAN AFTER EXAMINING THE RECORDS OF MORE THAN <mark>TWO DOZEN FINE POTENTIAL NOMINEES FOR THE POSITION OF SECRETARY OF THE INTERIOR</mark> I HAVE DECIDED TO")
    end
  end

  describe '#url_at_timecode' do
    it 'returns the expected URL with timecode' do
      expect(transcript_snippet_1.url_at_timecode).to eq("/catalog/cpb-aacip-111-21ghx7d6?term=ARKANSAS&proxy_start_time=50.24")
    end
  end

  describe 'query to terms array' do
    it 'removes punctuation from unquoted strings and capitalizes the user query' do
      expect(QueryToTermsArray.new(%(`show_, ^me %+/- the ?   "ice cream" $@*)).terms_array).to eq([%w(ICE CREAM), ["SHOW"], ["ME"]])
    end

    it 'leaves punctuation in quoted strings' do
      expect(QueryToTermsArray.new(%(the lost year "1958-59")).terms_array).to eq([["1958-59"], ["LOST"], ["YEAR"]])
    end

    it 'uses stopwords.txt to remove words not used in actual search' do
      expect(QueryToTermsArray.new(%(extremist is cheddar "president of the Eisenhower")).terms_array).to eq([%w(PRESIDENT OF THE EISENHOWER), ["EXTREMIST"], ["CHEDDAR"]])
    end

    it 'matches multiple sets of double quoted phrases' do
      expect(QueryToTermsArray.new(%("the french chef" with "Julia Child")).terms_array).to eq([%w(THE FRENCH CHEF), %w(JULIA CHILD)])
    end

    it 'strips all quotes if there are an odd number of quotation marks' do
      expect(QueryToTermsArray.new(%("broken quotation" marks")).terms_array).to eq([["BROKEN"], ["QUOTATION"], ["MARKS"]])
    end
  end

  describe 'view snippet helpers' do
    it 'creates a timecode transcript snippet for the frontend' do
      expect(transcript_snippet(transcript_snippet_1.snippet, "Moving Image", transcript_snippet_1.url_at_timecode)).to eq(%(\n      <span class=\"index-data-title\">From Transcript</span>:\n      <p style=\"margin-top: 0;\"> FOR THIS 15TH ANNIVERSARY CELEBRATION AND DEDICATION CEREMONY IS MR GEORGE CAMPBELL CHAIRMAN OF THE <mark>ARKANSAS</mark> EDUCATIONAL TELEVISION COMMISSION GOOD AFTERNOON DISTINGUISHED GUESTS LADIES AND GENTLEMEN \n        \n        <a href=\"/catalog/cpb-aacip-111-21ghx7d6?term=ARKANSAS&proxy_start_time=50.24\">\n          <button type=\"button\" class=\"btn btn-default snippet-link\">Watch from here</button>\n        </a>\n      \n      </p>\n    ))
    end

    it 'creates a transcript snippet for the frontend' do
      expect(transcript_snippet(transcript_snippet_4.snippet, "Moving Image")).to eq(%(\n      <span class=\"index-data-title\">From Transcript</span>:\n      <p style=\"margin-top: 0;\">AT THE OLD EXECUTIVE OFFICE BUILDING PRES RONALD REAGAN AFTER EXAMINING THE RECORDS OF MORE THAN <mark>TWO DOZEN FINE POTENTIAL NOMINEES FOR THE POSITION OF SECRETARY OF THE INTERIOR</mark> I HAVE DECIDED TO\n        \n      </p>\n    ))
    end

    it 'creates a caption snippet for the frontend' do
      expect(caption_snippet(caption_snippet1.snippet)).to eq(%(\n      <span class=\"index-data-title\">From Closed Caption</span>:\n      <p> THE SUMMER OF 1958 THAT ALLOWED THE LOST YEAR TO HAPPEN THE FIRST ONE WAS THAT THE SCHOOL BOARD HAD <mark>FILED FOR A DELAY</mark>  A NUMBER OF BUSINESS LEADERS PERSUADED A MAJORITY OF THE MEMBERS OF THE SCHOOL</p>\n    ))
    end
  end

  context 'when plaintext param is nil (for whatever reason)', :focus do
    it 'do not raise an error' do
      expect { Snippet.new('fake-id', [['fake query']], nil) }.to_not raise_error
      expect { TimecodeSnippet.new('fake-id', [['fake query']], nil, []) }.to_not raise_error
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end
