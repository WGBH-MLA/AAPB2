module SnippetHelper
  def self.build_snippets(solr_documents:, query:, matches:)
    snippets = {}
    solr_documents.each do |solr_doc|

      this_id = solr_doc[:id].gsub(/cpb-aacip./, 'cpb-aacip-')

      # only respond if highlighting set has this guid
      next unless matches[this_id]

      caption_file = CaptionFile.new(solr_doc.id)

      snippets[this_id] = {}

      # check for transcript/caption anno
      if solr_doc.transcript? && !query.nil?
        transcript_file = TranscriptFile.new(solr_doc.transcript_src)

        if transcript_file.file_type == TranscriptFile::JSON_FILE
          transcript_snippet = SnippetHelper::TranscriptSnippet.new('transcript' => transcript_file, 'id' => this_id, 'query' => query)
          snippets[this_id][:transcript] = transcript_snippet.highlight_snippet
          snippets[this_id][:transcript_timecode_url] = transcript_snippet.url_at_timecode
        elsif transcript_file.file_type == TranscriptFile::TEXT_FILE
          snippets[this_id][:transcript] = SnippetHelper.snippet_from_query(query, transcript_file.plaintext, 250, ' ')
        end
      end

      if !caption_file.captions_src.nil? && !query.nil?
        text = caption_file.text
        snippets[this_id][:caption] = SnippetHelper.snippet_from_query(query, text, 250, '.')
      end
    end
    snippets
  end

  def self.snippet_from_query(query, text, snippet_length, separator)
    return nil unless text
    # text = text.upcase.gsub(/[[:punct:]]/, '')
    text = text.upcase.gsub(/[^a-zA-z0-9\ \.\,:;!]/, '')
    term_hits = []

    query.each do |term|
      body = if term.split.length > 1
               SnippetHelper.process_compound_query_terms(term, text, snippet_length)
             else
               SnippetHelper.process_single_query_terms(query, text, snippet_length)
             end
      term_hits << body unless body.nil?
    end

    ActionController::Base.helpers.highlight(term_hits[0].truncate(snippet_length, separator: separator), query) unless term_hits.empty?
  end

  def self.process_single_query_terms(query, text, snippet_length)
    text_dictionary = text.gsub(/[[:punct:]]/, '').split
    intersection = query & text_dictionary

    return nil unless intersection && intersection.present?
    intersection_index = text.index(/\b(?:#{intersection[0]})\b/)
    start = if intersection_index && (intersection_index - snippet_length) > 0
              intersection_index
            else
              0
            end

    '...' + text[start..-1].to_s + '...'
  end

  def self.process_compound_query_terms(term, text, snippet_length)
    return nil unless text.include?(term)
    term_index = text.index(term)
    start = if term_index && (term_index - snippet_length) > 0
              term_index
            else
              0
            end
    '...' + text[start..-1].to_s + '...'
  end

  class TranscriptSnippet
    attr_reader :transcript
    attr_reader :snippet
    attr_reader :term
    attr_reader :query
    attr_reader :full_text
    attr_reader :timecode
    attr_reader :id

    def pop(hash, key)
      hash.delete(key) || raise("#{key} required")
    end

    def initialize(hash)
      @transcript = pop(hash, 'transcript')
      @query = pop(hash, 'query')
      @id = pop(hash, 'id')
      @full_text = transcript.plaintext
      raise "Unexpected attribute for TranscriptSnippet: #{hash}" unless hash.empty?
      snippet_from_query_with_timecode(@query, @transcript)
    end

    def highlight_snippet
      ActionController::Base.helpers.highlight(snippet, query) unless term.nil?
    end

    def url_at_timecode
      "/catalog/#{id}?term=#{term}&proxy_start_time=#{timecode}"
    end

    private

    def snippet_from_query_with_timecode(query, transcript)
      term_hits = []
      query.each do |term|
        snippet_and_timecode = process_query_term_with_timecode(term, transcript)
        term_hits << snippet_and_timecode unless snippet_and_timecode.nil?
      end

      return if term_hits.empty?

      @term = term_hits[0][:term]
      @timecode = term_hits[0][:timecode]
      @snippet = term_hits[0][:snippet]
    end

    # this should probably be refactored at some point
    def process_query_term_with_timecode(term, transcript)
      return unless transcript && transcript.file_type == TranscriptFile::JSON_FILE
      return unless full_text && full_text.upcase.include?(term.upcase)

      json = JSON.parse(transcript.content)
      total_transcript_parts = json["parts"].length

      json_segments_with_query = []

      json["parts"].each_with_index do |part, index|
        part["position"] = index

        text_for_part = if index < (total_transcript_parts - 4)
                          json["parts"][index..(index + 5)].map { |h| h["text"] }.join(' ')
                        else
                          json["parts"][index..total_transcript_parts].map { |h| h["text"] }.join(' ')
                        end

        # process one way if term is a single word and another if > 1
        text_dictionary = if term.split(' ').length > 1
                            text_for_part.upcase
                          else
                            text_for_part.gsub(/[[:punct:]]/, '').split.map(&:upcase)
                          end

        segment = {
          "id" => part["id"],
          "text" => text_for_part,
          "start_time" => part["start_time"],
          "speaker_id" => part["speaker_id"]
        }

        json_segments_with_query << segment if segment_is_good_snippet?(text_dictionary, term)

        # only need one good segment
        break unless json_segments_with_query.empty?
      end

      return if json_segments_with_query[0].nil?
      found_part = json_segments_with_query[0]

      { term: term, timecode: found_part["start_time"], snippet: format_snippet(term, found_part["text"]) }
    end

    # ensures we have some space around the found term
    def segment_is_good_snippet?(text_dictionary, term)
      return false unless text_dictionary.include?(term.upcase)
      back_pad = text_dictionary.length - (text_dictionary.index(term) + term.length)
      return true if text_dictionary.index(term) > 10 && back_pad > 10
      false
    end

    # builds 30 word snippet with the term close to the middle
    def format_snippet(term, snippet)
      return '...' + snippet + '...' unless snippet.split(' ').length > 30

      snippet_dictionary = snippet.upcase
      snippet_array = snippet_dictionary.partition(term.upcase)

      part_one = snippet_array[0].split(' ')
      part_two = snippet_array[2].split(' ')

      final_snippet = []

      part_one.reverse_each do |word|
        final_snippet.unshift(word) if final_snippet.length < (30 - term.length)
      end

      final_snippet << term

      part_two.each do |word|
        final_snippet << word if part_two.length - 2 && (final_snippet.length < 30)
      end

      '...' + final_snippet.join(' ') + '...'
    end
  end
end
