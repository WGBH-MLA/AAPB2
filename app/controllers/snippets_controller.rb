class SnippetsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher
  include ApplicationHelper
  include SnippetHelper

  def show
    respond_to do |format|

      format.json do
        # exit if bad input
        return [400, "ew!"] unless params["query"] && params["ids"] && params["ids"].all? {|id| AAPB.valid_id?(id) }

        ids = params["ids"].map {|id| normalize_guid(id) }

        # make OR query of ids
        solr_q = "+id:(#{ids.join(' OR ')})"
        snippet_data = {}

        # make array of words from users search query
        terms_array = query_to_terms_array(params["query"])

        # do, a search
        solr_docs = query_from_solr( solr_q )
        solr_docs.each do |solr_doc|
          
          # take in id, search query -> give back json of caption/ts snippet with markup
          this_id = normalize_guid(solr_doc[:id])
          snippet_data[this_id] = {}

          # check for transcript/caption anno
          if solr_doc.transcript?

            # put it here!
            transcript_file = TranscriptFile.new(solr_doc.transcript_src)
            if transcript_file.file_type == TranscriptFile::JSON_FILE && !transcript_file.content.empty?

              ts = TimecodeSnippet.new(this_id, terms_array, transcript_file.plaintext, JSON.parse(transcript_file.content)["parts"])
              # fix media type
              snippet_data[this_id][:snippet_body] = transcript_snippet(ts.snippet, "Moving Image", ts.url_at_timecode)
            elsif transcript_file.file_type == TranscriptFile::TEXT_FILE

              ts = Snippet.new(this_id, terms_array, transcript_file.plaintext)
              # fix it
              snippet_data[this_id][:snippet_body] = transcript_snippet( ts.snippet, "Moving Image" )
            end
          end

          if !snippet_data[this_id][:snippet_body]
            # only if no ts found

            caption_file = CaptionFile.new(solr_doc.id)

            unless caption_file.captions_src.nil?
              s = Snippet.new(this_id, terms_array, caption_file.text)
              snippet_data[this_id][:snippet_body] = caption_snippet( s.snippet )
            end
          end

          # if(snippet_data[:id][:snippet_body])
          #   return render json: snippet_data
          # end

        end


        return render json: snippet_data

      end
    end
  end

end
