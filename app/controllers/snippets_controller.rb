class SnippetsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher
  include ApplicationHelper
  include SnippetHelper

  def show
    respond_to do |format|
      format.json do

        require 'benchmark'
        times = {}
        times['Snippets#show (total)'] = Benchmark.realtime do

          # exit if bad input
          return [400, "Invalid Records"] unless params["query"] && params["ids"] && params["ids"].all? { |id| AAPB.valid_id?(id) }

          ids = params["ids"].map { |id| normalize_guid(id) }

          # make OR query of ids
          solr_q = "+id:(#{ids.join(' OR ')})"
          snippet_data = {}

          # make array of words from users search query
          terms_array = QueryToTermsArray.new(params["query"]).terms_array

          # do, a search
          solr_docs = query_from_solr(solr_q)
          solr_docs.each do |solr_doc|
            snippet_view_string = nil

            # take in id, search query -> give back json of caption/ts snippet with markup
            this_id = normalize_guid(solr_doc[:id])

            # check for transcript/caption anno
            if solr_doc.transcript?

              # put it here!
              transcript_file = TranscriptFile.new(solr_doc.id, solr_doc.transcript_src)

              if transcript_file.file_type == TranscriptFile::JSON_FILE && !transcript_file.file_content.empty?

                ts = TimecodeSnippet.new(this_id, terms_array, transcript_file.plaintext, JSON.parse(transcript_file.file_content)["parts"])
                # fix media type
                snippet_view_string = transcript_snippet(ts.snippet, "Moving Image", ts.url_at_timecode) if ts.snippet
              elsif transcript_file.file_type == TranscriptFile::TEXT_FILE

                ts = Snippet.new(this_id, terms_array, transcript_file.plaintext)
                # fix it
                snippet_view_string = transcript_snippet(ts.snippet, "Moving Image") if ts.snippet
              end
            end

            unless snippet_view_string
              # only if no valid ts was found
              caption_file = CaptionFile.retrieve_captions(solr_doc.id)
              
              if caption_file.file_present?
                s = Snippet.new(this_id, terms_array, caption_file.text)
                snippet_view_string = caption_snippet(s.snippet) if s.snippet
              end
            end

            if snippet_view_string
              # we actually created a snippet string
              snippet_data[this_id] = {}
              snippet_data[this_id] = snippet_view_string
            end
          end
        end

        Rails.logger.warn "\n\nBenchmark times:\n#{times.map{|k,v| "#{k}: #{v}"}.join("\n")}\n\n"

        return render json: snippet_data
      end
    end
  end
end
