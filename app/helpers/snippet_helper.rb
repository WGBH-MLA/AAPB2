module SnippetHelper
  def transcript_snippet(text, media_type, timecode_url)

    timecode_link = nil
    if timecode_url
      timecode_link = %(
        <a href="#{ timecode_url }">
          <button type="button" class="btn btn-default snippet-link">#{ media_type == 'Moving Image' ? "Watch" : "Listen" } from here</button>
        </a>
      )
    end

    %(
      <span class="index-data-title">From Transcript</span>:
      <p style="margin-top: 0;">#{ text }
        #{ timecode_link }
      </p>
    )
  end

  def caption_snippet(text)
    %(
      <span class="index-data-title">From Closed Caption</span>:
      <p>#{ text }</p>
    )
  end
  
  class Snippet
    def initialize(guid, terms_array, plaintext)
      @guid = guid
      # each term is either a single word or a "exact match" phrase
      # phrases come first in array, so if whole match is there WELL FIND IT
      @terms_array = terms_array
      @plaintext = plaintext.to_s.gsub(/[[:punct:]]/, '').upcase
    end


    def left_chunk_indicies(match_index)
      return 0..0 if match_index == 0
      chunk_start = match_index - 100 < 0 ? 0 : match_index - 100
      chunk_end = match_index - 1
      chunk_start..chunk_end
    end

    def right_chunk_indicies(match_index)
      match_index..match_index + 100
    end

    def snippet
      txt = nil
      this_term = nil

      @terms_array.each do |word_array|
        # stupid to rejoin word_array here but makes more sense than storing it twice
        this_term = word_array.join(" ")

        start_index = @plaintext.index(/\s{1}#{this_term}\s{1}|\s{1}#{this_term}\z|\A#{this_term}\s{1}/)
        next unless start_index

        # grab the chunk around our match and clean up the crap
        txt = (@plaintext[left_chunk_indicies(start_index)] + @plaintext[right_chunk_indicies(start_index)]).gsub(/\A\w+\s{1}/, '').gsub(/\s{1}\w+\z/, '')

        # and highlight
        break
      end

      highlight_snippet(txt, this_term) if txt
    end

    # shared methods
    def highlight_snippet(snippet, match_text)
      ActionController::Base.helpers.highlight(snippet, match_text) unless match_text.nil?
    end
  end

  class TimecodeSnippet < Snippet
    attr_reader :matched_term, :match_timecode

    def initialize(guid, terms_array, plaintext, json_parts)
      terms_array.each do |word_array|
        @match_timecode = find_match_timecode(json_parts, word_array)

        # used for the url
        @matched_term = word_array.join(" ")

        # make this here so we dont have too
        break if @match_timecode
      end
      super(guid, terms_array, plaintext)
    end

    def url_at_timecode
      "/catalog/#{@guid}?term=#{@matched_term}&proxy_start_time=#{@match_timecode}"
    end

    private

    def find_match_timecode(json_parts, words_to_match)
      query_terms_matched = 0
      match_timecode = nil

      json_parts.each do |part_hash|
        # we found every word in our query chunk, goodbye!

        part_hash["text"].split(" ").each do |word|
          return match_timecode if query_terms_matched == words_to_match.length

          # get first occurrence of each word and pair it with the most accurate time stamp we have

          if word.upcase == words_to_match[query_terms_matched]
            # record the tc because we started a match and we werent already a'matchin
            match_timecode = part_hash["start_time"] if query_terms_matched == 0

            query_terms_matched += 1
          else
            query_terms_matched = 0
          end
        end
      end

      match_timecode
    end
  end
end
