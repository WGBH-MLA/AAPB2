require 'cgi'

module QueryMaker
  # TODO: Something in Blacklight is already doing this.
  FACET_RE = /^f\[\w+\]\[\]$/
  def self.translate(query_string)
    hash = CGI.parse(query_string)
    q = hash.delete('q')
    facets = hash.select { |key| key.match(FACET_RE) }
    hash = hash.reject { |key| key.match(FACET_RE) }
    extras = hash.keys - ['utf8']

    fail("Unrecognized params: #{extras}") unless extras.empty?
    fail("Expected only one 'q'") if q && q.count > 1
    
    pairs = facets.flat_map do|bracket_key, array_value|
      simple = bracket_key.sub(/f\[/, '').sub(/\]\[\]/, '')
      array_value.map { |value| [simple, value] }
    end

    pairs << ['text', q.first] if q

    pairs.map do|k, v|
      "#{k}:\"#{v.gsub('"', '\\"')}\""
    end.join(' ')
  end
end
