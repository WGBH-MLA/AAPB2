require 'yaml'

class VocabMap

  def self.for(vocab)
    path = File.dirname(File.dirname(File.dirname(__FILE__)))+"/config/vocab-maps/#{vocab}-type-map.yml"
    VocabMap.new(path)
  end
  
  def initialize(path)
    @map = YAML.load_file(path)
    raise "Unexpected datatype (#{@map.class}) in #{path}" unless @map.class == Psych::Omap

    @case_map = Hash[@map.values.uniq.map{|value|[value.downcase,value]}]
    raise "Case discrepancy on RHS in #{path}" if @case_map.count != @map.values.uniq.count

    hidden_keys = @map.select{|key,value| map_string(key)!=value}.keys
    raise "Hidden keys #{hidden_keys} in #{path}" unless hidden_keys.empty?

    raise "No default mapping in #{path}" unless @map['']
  end
  
  def authorized_names
    @map.values.uniq
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
    nodes.each{|node| map_node(node)}
  end

  def map_reorder_nodes(nodes)
    # TODO: change the argument to an xpath so we can validate that a "//" is being used.

    # NOTE: The '//' XPath is wildly inefficient, but a tighter search like '/*/pbcoreTitle'
    # returns no results if the title element was inserted just above. My suspicion is that
    # REXML doesn't fully update its internal representation of the parent after node insertions,
    # but forcing a full traversal with '//' gets the job done.
    # 
    # THIS IS HORRIBLE!!!

    if !nodes.empty?
      map_nodes(nodes)
      attribute_name = nodes.first.name
      nodes.each do |node|
        raise "Must be attribute: #{node}" unless node.node_type == :attribute
        raise "Attribute name must be '#{name}': #{node}" unless node.name == attribute_name
      end

      ordering = Hash[@map.values.uniq.each_with_index.map{|e,i| [e,i]}]

      nodes.map{ |attr|
        attr.element.dup
      }.sort_by{ |element|
        ordering[element.attributes[attribute_name]]
      }.each{ |element|
        nodes[0].element.parent.insert_before(nodes[0].element,element)
      }
      nodes.each{|attr| attr.element.parent.delete(attr.element)}
    end
  end

  private

  def self.delete(node)
    node.parent.elements.delete(node)
  end

end