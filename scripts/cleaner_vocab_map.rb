require 'yaml'

class Cleaner
  class VocabMap
    
    def initialize(path)
      @map = YAML.load_file(path)
      raise "Unexpected datatype (#{@map.class}) in #{path}" unless @map.class == Psych::Omap

      @case_map = Hash[@map.values.uniq.map{|value|[value.downcase,value]}]
      raise "Case discrepancy on RHS in #{path}" if @case_map.count != @map.values.uniq.count

      hidden_keys = @map.select{|key,value| map_string(key)!=value}.keys
      raise "Hidden keys #{hidden_keys} in #{path}" unless hidden_keys.empty?

      raise "No default mapping in #{path}" unless @map['']
    end
    
    def map_string(s)
      return @case_map[s.downcase] ||
        @map.select{|key| s.downcase.include? key.downcase}.values.first ||
        raise("No match found for '#{s}'")
    end
    
    def map_node(node)
      unless node.respond_to? 'text'
        # Make attribute node act like element node
        def node.text
          self.element.attributes[self.name]
          # self.value doesn't change when the value is reset. Agh.
        end
        def node.text=(s)
          self.element.attributes[self.name]=s
        end
      end
      node.text = map_string(node.text)
    end
    
    def map_nodes(nodes)
      # TODO
    end
    
    def map_reorder_nodes(nodes)
      # TODO
    end
    
  end
end