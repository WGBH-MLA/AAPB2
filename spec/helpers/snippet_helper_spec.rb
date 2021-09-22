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
  let(:json_transcript) { TranscriptFile.new(json_url) }

  txt_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-507-0000000j8w/cpb-aacip-507-0000000j8w-transcript.txt'
  let(:txt_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-507-0000000j8w-transcript.txt') }
  let(:txt_transcript) { TranscriptFile.new(txt_url) }


  # queries are split up into no-stopword arrays in appl helper
  let(:transcript_query_1) { [ ["ARKANSAS"] ] }
  let(:transcript_query_2) { [ ["SENATOR", "PRYOR"] ] }
  let(:transcript_query_3) { [ ["FILED", "FOR", "A", "DELAY"], ["NEVER", "GONNA", "GET", "MATCHED"] ] }
  let(:transcript_query_4) { [ ["TWO", "DOZEN", "FINE", "POTENTIAL", "NOMINEES", "FOR", "THE", "POSITION", "OF", "SECRETARY", "OF", "THE", "INTERIOR"] ] }


  let(:srt_example) { File.read('./spec/fixtures/captions/srt/srt_example.srt') }
  let(:caption_file) { CaptionFile.new("1a2b") }


  # single
  let(:transcript_snippet_1) { TimecodeSnippet.new('cpb-aacip-111-21ghx7d6', transcript_query_1, json_transcript.plaintext, JSON.parse(json_transcript.content)["parts"] ) }
  # compound
  let(:transcript_snippet_2) { TimecodeSnippet.new('cpb-aacip-111-21ghx7d6', transcript_query_2, json_transcript.plaintext, JSON.parse(json_transcript.content)["parts"] ) }
  # caption
  let(:transcript_snippet_3) { Snippet.new('cpb-aacip-111-21ghx7d6', transcript_query_3, caption_file.text ) }
  # txt
  let(:transcript_snippet_4) { Snippet.new('cpb-aacip-507-0000000j8w', transcript_query_4, txt_transcript.plaintext ) }


  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/transcripts/ with the same filename they have in S3.
    WebMock.stub_request(:get, json_url).to_return(body: json_example)
    WebMock.stub_request(:get, txt_url).to_return(body: txt_example)


    CaptionFile.any_instance.stub(:captions_src).and_return('https://s3.amazonaws.com/americanarchive.org/captions/1a2b.srt')
    WebMock.stub_request(:get, caption_file.srt_url).to_return(body: srt_example)
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
      expect(transcript_snippet_3.snippet).to eq(" THE SUMMER OF 1958 THAT ALLOWED THE LOST YEAR TO HAPPEN THE FIRST ONE WAS THAT THE SCHOOL BOARD HAD <mark>FILED FOR A DELAY</mark>  A NUMBER OF BUSINESS LEADERS PERSUADED A MAJORITY OF THE MEMBERS OF THE SCHOOL")
    end

    it 'initializes with expected attrs for txt file' do
      expect(transcript_snippet_4.snippet).to eq("AT THE OLD EXECUTIVE OFFICE BUILDING PRES RONALD REAGAN AFTER EXAMINING THE RECORDS OF MORE THAN <mark>TWO DOZEN FINE POTENTIAL NOMINEES FOR THE POSITION OF SECRETARY OF THE INTERIOR</mark> I HAVE DECIDED TO")
    end    
  end

  describe '#url_at_timecode' do
    it 'returns the expected URL with timecode' do
      expect(transcript_snippet_1.url_at_timecode).to eq("/catalog/cpb-aacip-111-21ghx7d6?term=ARKANSAS&#at_50.24_s")
    end
  end

  describe 'query to terms array' do
    # it 'removes punctuation from and capitalizes the user query' do
    #   expect(clean_query_for_snippet(query_with_punctuation)).to eq(test_array)
    # end

    it 'uses stopwords.txt to remove words not used in actual search' do
      expect(query_to_terms_array(%(extremist is cheddar "president of the Eisenhower"))).to eq([["PRESIDENT", "OF", "THE", "EISENHOWER"], ["EXTREMIST"], ["CHEDDAR"]])
    end
  end
  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end
