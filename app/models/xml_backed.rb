module XmlBacked
  def initialize(xml)
    @xml = xml
    @doc = REXML::Document.new xml
  end

  def xpath(xpath)
    REXML::XPath.match(@doc, xpath).tap do |matches|
      if matches.length != 1
        raise NoMatchError, "Expected 1 match for '#{xpath}'; got #{matches.length}"
      else
        return cdata_present?(matches.first) ? matches.first.cdatas.first.to_s : XmlBacked.text_from(matches.first)
      end
    end
  end

  def xpath_optional(xpath)
    REXML::XPath.match(@doc, xpath).tap do |matches|
      if matches.length > 1
        raise NoMatchError, "Expected at most 1 match for '#{xpath}'; got #{matches.length}"
      elsif matches.first
        return XmlBacked.text_from(matches.first)
      else
        return nil
      end
    end
  end

  def xpaths(xpath)
    # Need to process cdata children if they're present
    REXML::XPath.match(@doc, xpath).map { |node| cdata_present?(node) ? node.cdatas.first.to_s : XmlBacked.text_from(node) }
  end

  def self.text_from(node)
    ((node.respond_to?('text') ? node.text : node.value) || '').strip
  end

  def cdata_present?(node)
    node.respond_to?('cdatas') && !node.cdatas.empty?
  end

  def pairs_by_type(element_xpath, attribute_xpath)
    REXML::XPath.match(@doc, element_xpath).map do |node|
      key = REXML::XPath.first(node, attribute_xpath)
      [
        key ? key.value : nil,
        node.text
      ]
    end
  end

  def hash_by_type(element_xpath, attribute_xpath)
    Hash[pairs_by_type(element_xpath, attribute_xpath)]
  end

  # TODO: If we can just iterate over pairs, we don't need either of these.
  #
  #  def multi_hash_by_type(element_xpath, attribute_xpath) # Not tested
  #    Hash[
  #      pairs_by_type(element_xpath, attribute_xpath).group_by{|(key,value)| key}.map{|key,pair_list|
  #        [key, pair_list.map{|(key,value)| value}]
  #      }
  #    ]
  #  end

  class NoMatchError < StandardError
  end
end
