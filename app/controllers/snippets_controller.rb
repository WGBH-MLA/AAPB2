class SnippetsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher
  include ApplicationHelper
  include SnippetHelper

  def show
    respond_to do |format|

      format.json do
        return [400, "ew!"] unless params["id"] && params["query"]
        snippet_data = {}

        terms_array = query_to_terms_array(params["query"])

        @response, solr_doc = fetch_from_blacklight(params['id'])
        # take in id, search query -> give back json of caption/ts snippet with markup
        this_id = normalize_guid(solr_doc[:id])
        snippet_data[:id] = this_id

        # check for transcript/caption anno
        if solr_doc.transcript?

          # put it here!
          transcript_file = TranscriptFile.new(solr_doc.transcript_src)
          if transcript_file.file_type == TranscriptFile::JSON_FILE && !transcript_file.content.empty?

            ts = TimecodeSnippet.new(this_id, terms_array, transcript_file.plaintext, JSON.parse(transcript_file.content)["parts"])
            # fix media type
            snippet_data[:snippet_body] = transcript_snippet(ts.snippet, "Moving Image", ts.url_at_timecode)
          elsif transcript_file.file_type == TranscriptFile::TEXT_FILE

            ts = Snippet.new(this_id, terms_array, transcript_file.plaintext)
            # fix it
            snippet_data[:snippet_body] = transcript_snippet( ts.snippet, "Moving Image" )
          end
        end

        if !snippet_data[:transcript]
          caption_file = CaptionFile.new(solr_doc.id)

          unless caption_file.captions_src.nil?
            s = Snippet.new(this_id, terms_array, caption_file.text)
            snippet_data[:snippet_body] = caption_snippet( s.snippet )
          end
        end

        if(snippet_data[:snippet_body])
          return render json: snippet_data
        end

      end
    end
  end

end
