require 'rexml/document'
require 'set'
require_relative '../../app/models/vocab_map'

class Cleaner # rubocop:disable Metrics/ClassLength
  attr_reader :match

  def initialize
    @asset_type_map = VocabMap.for('asset')
    @date_type_map = VocabMap.for('date')
    @title_type_map = VocabMap.for('title')
    @description_type_map = VocabMap.for('description')
    @genre_type_map = VocabMap.for('genre')
    @topic_type_map = VocabMap.for('topic')
  end

  def clean(dirty_xml, name='not specified')
    dirty_xml.gsub!("xsi:xmlns='http://www.w3.org/2001/XMLSchema-instance'",
                    "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'")
    dirty_xml.gsub!("xmlns:xsi='xsi'", '')
    doc = REXML::Document.new(dirty_xml)
    @current_name = name # A little bit icky, but makes the match calls simpler, rather than passing another parameter.

    # pbcoreAssetType:

    match(doc, '/pbcoreAssetType') { |node|
      @asset_type_map.map_node(node)
    }

    # TODO: insert assetType if not given.

    match(doc, '/pbcoreAssetDate') { |node|
      match = node.text.match(/^(\d{4})/)
      Cleaner.delete(node) unless match && match[1].to_i.between?(1900, Time.now.year)
    }

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
    
    match(doc, '/pbcoreTitle') { |node|
      if (node.text !~ /[A-Z]/ || node.text !~ /[a-z]/) && node.text =~ /[a-zA-Z]/
        # ie, either all upper or all lower, and it has letters.
        node.text = node.text.downcase
          .gsub(/\b\w/) { |match|
            # First letters
            match.upcase 
          }
          .gsub(/\b(
              AFN|AG|ASMW|BSO|CEO|CMU|CO|CTE|DCA
              |ETV|HBCU|HIKI|ICC|II|IPR|ITV|KAKM|KBDI|KCAW|KCMU
              |KDNA|KEET|KET|KETC|KEXP|KEZI|KFME|KGNU|KLPA|KMED|KMOS
              |KNBA|KNME|KOAC|KOCE|KODE|KOZJ|KOZK|KPFA|KQED|KRMA|KSYS
              |KTCA|KUCB|KUED|KUHF|KUNM|KUOW|KUSC|KUSP|KUT|KUVO|KVIE
              |KWSO|KWSU|KXCI|KYUK|LA|LICBC|LSU|LYMI|MA|MELE|MIT|MSU
              |NAC|NAEB|NE|NEA|NETA|NJPBA|NY|NYS|OEB|OPB|OPTV|ORC
              |PSA|RAETA|SCETV|SOEC|TIU|UC|UCB|UCTV
              |UHF|UM|UNC|US|USA|UVM|UW|WBAI|WBEZ|WBRA|WCNY|WCTE|WDIY
              |WEDH|WEDU|WEOS|WERU|WETA|WEXT|WFIU|WFMU|WFYI|WGBY|WGCU
              |WGUC|WGVU|WHA|WHRO|WHUR|WHUT|WHYY|WIAA|WKAR|WLAE
              |WMEB|WNED|WNET|WNYC|WOJB|WOSU|WQED|WQEJ|WRFA|WRNI|WSIU
              |WTIP|WTIU|WUFT|WUMB|WUNC|WUSF|WVIA|WVIZ|WWOZ|WXXI|WYCC
              |WYSO|WYSU|YSU)\b/xi) { |match|
            # Based on:
            #   ruby -ne '$_.match(/[A-Z]{2,}/){|m| puts m}' config/organizations.yml \
            #     | grep '[AEIOUY]' | sort | uniq | ruby -ne 'print $_.chop; print "|"'
            # Removed: AM, AMBER, COLORES, COSI, FETCH, NET, RISE, SAM, STEM, TOLD, WILL
            match.upcase
          }
          .gsub(/\b[^AEIOUY]+\b/i) { |match|
            # Unknown acronyms
            match.upcase
          }
          .gsub(/\b(a|an|the|and|but|or|for|nor|yet|as|at|by|for|in|of|on|to|from)\b/i) { |match|
            match.downcase
          }
          .gsub(/^./) { |match|
            match.upcase
          }
      end
    }

    @title_type_map.map_reorder_nodes(
      REXML::XPath.match(doc, '//pbcoreTitle/@titleType'))

    # pbcoreDescription:

    @description_type_map.map_reorder_nodes(
      REXML::XPath.match(doc, '//pbcoreDescription/@descriptionType'))

    # pbcoreGenre:

    match(doc, '/pbcoreGenre') { |node|
      genre = @genre_type_map.map_string(node.text)
      topic = @topic_type_map.map_string(node.text)
      
      if topic.empty? && !genre.empty?
        node.text = genre
        node.add_attribute('annotation', 'genre')
      elsif genre.empty? && !topic.empty?
        node.text = topic
        node.add_attribute('annotation', 'topic')
      else
        Cleaner.delete(node)
      end
    }
    
    # pbcoreRelation:

    match(doc, '/pbcoreRelation[not(pbcoreRelationType)]') { |node|
      Cleaner.delete(node)
    }

    match(doc, '/pbcoreRelation') { |node|
      if node.elements[1].name == 'pbcoreRelationIdentifier'
        Cleaner.swap_children(node)
      end
    }

    # pbcoreCoverage:

    match(doc, '/pbcoreCoverage[coverageType[not(node())]]') { |node|
      Cleaner.delete(node)
    }

    match(doc, '/pbcoreCoverage/coverageType') { |node|
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

    # pbcoreInstantiation:

    match(doc, '/pbcoreInstantiation[not(instantiationIdentifier)]') { |node|
      node[0, 0] = REXML::Element.new('instantiationIdentifier')
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

    match(doc, '/pbcoreInstantiation/instantiationDimensions/@unitOfMeasure') { |node|
      node.name = 'unitsOfMeasure'
    }

    match(doc, '/pbcoreInstantiation/instantiationMediaType' \
      '[. != "Moving Image" and . != "Sound" and . != "other"]') { |node|
      node.text = 'other'
    }

    match(doc, '/pbcoreInstantiation/instantiationLanguage') { |node|
      Cleaner.clean_language(node)
    }

    match(doc, '/pbcoreInstantiation/instantiationEssenceTrack/essenceTrackLanguage') { |node|
      Cleaner.clean_language(node)
    }

    # duplicate value removal
    
    seen_values = Set.new
    ['/pbcoreTitle', '/pbcoreDescription', '/pbcoreRightsSummary/rightsSummary', #
        '/pbcoreInstantiation/instantiationIdentifier'].each { |name|
        
      
      match(doc, name) { |node|
        if seen_values.include?(node.text)
          Cleaner.delete(node)
        else
          seen_values.add(node.text)
        end
      }
    }
    
    # formatting:

    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    output = []
    formatter.write(doc, output)
    output.join('').sub("<\?xml version='1\.0' encoding='UTF-8'\?> \n", '')
    # XML declaration seems to be output with trailing space, which makes tests just a bit annoying.
    # Just stripping it should be fine.
  end

  private

  def self.clean_language(node)
    node.text = node.text[0..2].downcase # Rare problem; Works for English, but not for other languages.
    node.parent.elements.delete(node) if node.text !~ /^[a-z]{3}/
  end

  def match(doc, xpath_fragment)
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument' + xpath_fragment).each do |node|
      yield node
    end
  end

  def self.any(pre, list)
    list.map { |item| pre + item }.join('|')
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
