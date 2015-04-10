require 'cgi'

module QueryMaker
  # TODO: Something in Blacklight is already doing this.
  FACET_RE = /^f\[\w+\]\[\]$/
  def self.translate(query_string)
    hash = CGI.parse(query_string)
    q = hash.delete('q')
    search_field = hash.delete('search_field')
    facets = hash.select{|key| key.match(FACET_RE)}
    hash = hash.reject{|key| key.match(FACET_RE)}
    extras = hash.keys - ['utf8'] 
    
    fail("Unrecognized params: #{extras}") if !extras.empty?
    fail("Expected only one 'q'") if q && q.count > 1
    fail("Expected only one 'search_field'") if search_field && search_field.count > 1
    fail("Only 'all_fields' is supported") if search_field && 
      search_field.count == 1 && search_field.first != 'all_fields'
    
    pairs = facets.map{|bracket_key,array_value|
      simple = bracket_key.sub(/f\[/,'').sub(/\]\[\]/,'')
      array_value.map{|value| [simple,value]}
    }.flatten(1)
    
    pairs << ['text', q.first] if q 
    
    pairs.map {|k,v|
      "#{k}:\"#{v.gsub('"','\\"')}\""
    }.join(' ')
  end
end