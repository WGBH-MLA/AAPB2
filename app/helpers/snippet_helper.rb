module SnippetHelper
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
      "/catalog/#{id}?term=#{term}&#at_#{timecode}_s"
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
      return unless transcript.file_type == TranscriptFile::JSON_FILE
      return unless full_text.upcase.include?(term.upcase)

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

  #### END TRANSCRIPT_SNIPPET CLASS ####

  def snippet_from_query(query, text, snippet_length, separator)
    return nil unless text
    # text = text.upcase.gsub(/[[:punct:]]/, '')
    text = text.upcase.gsub(/[^a-zA-z0-9\ \.\,:;!]/, '')
    term_hits = []

    query.each do |term|
      body = if term.split.length > 1
               process_compound_query_terms(term, text, snippet_length)
             else
               process_single_query_terms(query, text, snippet_length)
             end
      term_hits << body unless body.nil?
    end

    ActionController::Base.helpers.highlight(term_hits[0].truncate(snippet_length, separator: separator), query) unless term_hits.empty?
  end

  private

  def process_single_query_terms(query, text, snippet_length)
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

  def process_compound_query_terms(term, text, snippet_length)
    return nil unless text.include?(term)
    term_index = text.index(term)
    start = if term_index && (term_index - snippet_length) > 0
              term_index
            else
              0
            end
    '...' + text[start..-1].to_s + '...'
  end
end
