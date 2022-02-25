class SnippetsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher
  include SnippetHelper

  def show
    return [400, "ew!"] unless params["id"] && params["query"]
    snippet_data = {}

    terms_array = query_to_terms_array(params["query"])

    @response, @document = fetch_from_blacklight(params['id'])
    # take in id, search query -> give back json of caption/ts snippet with markup
    this_id = normalize_guid(solr_doc[:id])

    snippet_data[:id] = this_id

    # only respond if highlighting set has this guid
    # next unless fixed_matches[this_id]

    caption_file = CaptionFile.new(solr_doc.id)
    # @snippets[this_id] = {}

    # check for transcript/caption anno
    if solr_doc.transcript?

      # put it here!
      transcript_file = TranscriptFile.new(solr_doc.transcript_src)
      if transcript_file.file_type == TranscriptFile::JSON_FILE && !transcript_file.content.empty?

        ts = TimecodeSnippet.new(this_id, terms_array, transcript_file.plaintext, JSON.parse(transcript_file.content)["parts"])

        snippet_data[:transcript] = ts.snippet
        snippet_data[:transcript_timecode_url] = ts.url_at_timecode
      elsif transcript_file.file_type == TranscriptFile::TEXT_FILE

        ts = Snippet.new(this_id, terms_array, transcript_file.plaintext)
        snippet_data[:transcript] = ts.snippet
      end

    end

    if(!)

    unless caption_file.captions_src.nil?
      s = Snippet.new(this_id, terms_array, caption_file.text)
      snippet_data[:caption] = s.snippet
    end
  end

end
