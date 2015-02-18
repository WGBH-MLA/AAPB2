require 'rexml/document'
require 'set'
require_relative '../../app/models/vocab_map'

class Cleaner
  
  attr_reader :report
  
  def initialize
    @asset_type_map = VocabMap.for('asset')
    @date_type_map = VocabMap.for('date')
    @title_type_map = VocabMap.for('title')
    @description_type_map = VocabMap.for('description')
    
    @report = {}
    def @report.to_s
      out = ''
      self.sort.each do |category,set|
        out << "#{category}\n"
        set.sort.each do |member|
          out << "\t#{member}\n"
        end
      end
      out
    end
  end
  
  def clean(dirty_xml, name)
    dirty_xml.gsub!("xsi:xmlns='http://www.w3.org/2001/XMLSchema-instance'", "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'")
    dirty_xml.gsub!("xmlns:xsi='xsi'","")
    doc = REXML::Document.new(dirty_xml)
    @current_name = name # A little bit icky, but makes the match calls simpler, rather than passing another parameter.
    
    # pbcoreAssetType:
    
    match_no_report(doc, '/pbcoreAssetType') { |node|
      @asset_type_map.map_node(node)
    }
    
    # TODO: insert assetType if not given.
    
    # dateType
    
    match(doc, '/pbcoreAssetDate[not(@dateType)]') { |node|
      node.attributes['dateType'] = ''
    }
    
    @date_type_map.map_reorder_nodes(REXML::XPath.match(doc, '//pbcoreAssetDate/@dateType'))
    # TODO: sort instantiation dates? Though with multiple instantiations,
    # keeping the right date with the right instantiation might be hard.
    
    # pbcoreIdentifier:
    
    match(doc, '/pbcoreIdentifier[not(@source)]') { |node|
      node.attributes['source'] = 'unknown'
    }
    
    # pbcoreTitle:
    
    match(doc, '[not(pbcoreTitle)]') {
      # If there is a match, it's the root node, so no "node" parameter is needed.
      Cleaner.insert_after_match(
        doc,
        '/pbcoreDescriptionDocument/pbcoreIdentifier',
        REXML::Document.new('<pbcoreTitle titleType="Program">unknown</pbcoreTitle>')
      )
    }
    
    match(doc, '/pbcoreTitle[not(@titleType)]') { |node|
      node.attributes['titleType'] = ''
    }
    
    @title_type_map.map_reorder_nodes(REXML::XPath.match(doc, '//pbcoreTitle/@titleType'))
    
    # pbcoreDescription:
    
    @description_type_map.map_reorder_nodes(REXML::XPath.match(doc, '//pbcoreDescription/@descriptionType'))
    
    # pbcoreRelation:
    
    match(doc, '/pbcoreRelation[not(pbcoreRelationType)]') { |node|
       Cleaner.delete(node)
    }
    
    match_no_report(doc, '/pbcoreRelation') { |node|
      if node.elements[1].name == 'pbcoreRelationIdentifier'
        add_report('swapped pbcoreRelation children', @current_name)
        Cleaner.swap_children(node) 
      end
    }
    
    # pbcoreCoverage:
    
    match(doc, '/pbcoreCoverage[coverageType[not(node())]]') { |node|
       Cleaner.delete(node)
    }
    
    match_no_report(doc, '/pbcoreCoverage/coverageType') { |node|
      # TODO: report, or tighter XPath
      node.text = node.text.capitalize
    }
    
    # pbcoreCreator/Contributor/Publisher:
    
    match(doc, '/pbcoreCreator[not(creator)]') { |node|
      Cleaner.delete(node)
    }
    match(doc, '/pbcoreContributor[not(contributor)]') { |node|
      Cleaner.delete(node)
    }
    match(doc, '/pbcorePublisher[not(publisher)]') { |node|
      Cleaner.delete(node)
    }
    
    # pbcoreRightsSummary:
    
    match_no_report(doc, '[not(pbcoreRightsSummary/rightsEmbedded/AAPB_RIGHTS_CODE)]') { |node|
      Cleaner.insert_after_match(
        node,
        Cleaner.any('pbcore', %w(Description Genre Relation Coverage AudienceLevel AudienceRating Creator Contributor Publisher RightsSummary)),
        REXML::Document.new('<pbcoreRightsSummary><rightsEmbedded><AAPB_RIGHTS_CODE>' +
                          'ON_LOCATION_ONLY' +
                          '</AAPB_RIGHTS_CODE></rightsEmbedded></pbcoreRightsSummary>')
      )
    }
    
    # pbcoreInstantiation:
    
    match(doc, '/pbcoreInstantiation[not(instantiationIdentifier)]') { |node|
      node[0,0] = REXML::Element.new('instantiationIdentifier')
    }
    
    match(doc, '/pbcoreInstantiation/instantiationIdentifier[not(@source)]') { |node|
      node.attributes['source'] = 'unknown'
    }
    
    match(doc, '/pbcoreInstantiation[not(instantiationLocation)]') { |node|
      Cleaner.insert_after_match(
        node, 
        Cleaner.any('instantiation', %w(Identifier Date Dimensions Physical Digital Standard)),
        REXML::Element.new('instantiationLocation')
      )
    }
    
    match(doc, '/pbcoreInstantiation[not(instantiationMediaType)]') { |node|
      Cleaner.insert_after_match(
        node,
        'instantiationLocation',
        REXML::Element.new('instantiationMediaType')
      )
    }
    
    match(doc, '/pbcoreInstantiation/instantiationMediaType[. != "Moving Image" and . != "Sound" and . != "other"]') { |node|
      node.text='other'
    }
    
    match_no_report(doc,'/pbcoreInstantiation/instantiationLanguage') { |node|
      # TODO: report
      node.text = node.text[0..2].downcase # Rare problem; Works for English, but not for other languages.
      node.parent.elements.delete(node) if node.text !~ /^[a-z]{3}/
    }
    
    # formatting:
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    output = []
    formatter.write(doc, output)
    output.join('').gsub(/<\?xml version='1\.0' encoding='UTF-8'\?>\s*/, '')
    # XML declaration seems to be output with trailing space, which makes tests just a bit annoying.
    # Just stripping it should be fine.
  end
  
  private
  
  def add_report(category, instance)
    @report[category] ||= Set.new
    @report[category].add(instance)
  end

  def match(doc, xpath_fragment)
    @current_category = xpath_fragment # TODO: Is there a better way to get this into the each-scope?
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument'+xpath_fragment).each do |node| 
      add_report(@current_category, @current_name)
      yield node
    end
  end
  
  def match_no_report(doc, xpath_fragment)
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument'+xpath_fragment).each do |node| 
      yield node
    end
  end
  
  def self.any(pre, list)
    list.map{|item| pre+item}.join('|')
  end
  
  def self.insert_after_match(doc, xpath, insert)
    REXML::XPath.match(doc, xpath).last.next_sibling = insert
  end
  
  def self.swap_children(node)
    # Not really happy with this approach.
    id = node.elements[1]
    type = node.elements[2]
    node.elements.delete_all '*'
    node.elements[1] = type
    node.elements[2] = id
  end
  
  def self.delete(node)
    node.parent.elements.delete(node)
  end
  
end

if __FILE__ == $0
  cleaner = Cleaner.new
  ARGV.each do |path|
    dirty_xml = File.read(path)
    puts cleaner.clean(dirty_xml, path)
  end
end