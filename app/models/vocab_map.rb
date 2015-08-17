require 'yaml'

class VocabMap
  def self.for(vocab)
    path = Rails.root + "config/vocab-maps/#{vocab}-type-map.yml"
    VocabMap.new(path)
  end

  def initialize(path)
    @map = YAML.load_file(path)
    fail "Unexpected datatype (#{@map.class}) in #{path}" unless @map.class == Psych::Omap

    @case_map = Hash[@map.values.uniq.map { |value| [value.downcase, value] }]
    fail "Case discrepancy on RHS in #{path}" if @case_map.count != @map.values.uniq.count

    hidden_keys = @map.select { |key, value| map_string(key) != value }.keys
    fail "Hidden keys #{hidden_keys} in #{path}" unless hidden_keys.empty?

    fail "No default mapping in #{path}" unless @map['']
  end

  def authorized_names
    @map.values.uniq.select { |name| !name.empty? }
  end

  def map_string(s)
    return nil unless s
    @case_map[s.downcase] ||
      @map.select { |key| s.downcase.include? key.downcase }.values.first ||
      fail("No match found for '#{s}'")
  end

  def map_node(node)
    unless node.respond_to? 'text'
      # Make attribute node act like element node
      def node.text
        element.attributes[name]
        # self.value doesn't change when the value is reset. Agh.
      end
      def node.text=(s)
        element.attributes[name] = s
      end
    end
    node.text = map_string(node.text)
  end

  def map_nodes(nodes)
    nodes.each { |node| map_node(node) }
  end

  def map_reorder_nodes(nodes)
    # TODO: change the argument to an xpath so we can validate that a "//" is being used.

    # NOTE: The '//' XPath is wildly inefficient, but a tighter search like '/*/pbcoreTitle'
    # returns no results if the title element was inserted just above. My suspicion is that
    # REXML doesn't fully update its internal representation of the parent after node insertions,
    # but forcing a full traversal with '//' gets the job done.
    #
    # THIS IS HORRIBLE!!!

    return if nodes.empty?

    map_nodes(nodes)
    attribute_name = nodes.first.name
    nodes.each do |node|
      fail "Must be attribute: #{node}" unless node.node_type == :attribute
      fail "Attribute name must be '#{name}': #{node}" unless node.name == attribute_name
    end

    ordering = Hash[@map.values.uniq.each_with_index.map { |e, i| [e, i] }]

    nodes.map do |attr|
      attr.element.dup
    end.sort_by do |element|
      ordering[element.attributes[attribute_name]]
    end.each do |element|
      nodes[0].element.parent.insert_before(nodes[0].element, element)
    end
    nodes.each { |attr| attr.element.parent.delete(attr.element) }
  end
end
