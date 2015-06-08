require 'rexml/document'
require 'set'
require_relative '../../app/models/vocab_map'

class Cleaner # rubocop:disable Metrics/ClassLength
  attr_reader :report

  def initialize
    @asset_type_map = VocabMap.for('asset')
    @date_type_map = VocabMap.for('date')
    @title_type_map = VocabMap.for('title')
    @description_type_map = VocabMap.for('description')
    @genre_type_map = VocabMap.for('genre')

    @report = {}
    def @report.to_s
      out = ''
      sort.each do |category, set|
        out << "#{category}\n"
        set.sort.each do |member|
          out << "\t#{member}\n"
        end
      end
      out
    end
  end

  def clean(dirty_xml, name='not specified')
    dirty_xml.gsub!("xsi:xmlns='http://www.w3.org/2001/XMLSchema-instance'",
                    "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'")
    dirty_xml.gsub!("xmlns:xsi='xsi'", '')
    doc = REXML::Document.new(dirty_xml)
    @current_name = name # A little bit icky, but makes the match calls simpler, rather than passing another parameter.

    # pbcoreAssetType:

    match_no_report(doc, '/pbcoreAssetType') { |node|
      @asset_type_map.map_node(node)
    }

    # TODO: insert assetType if not given.

    match_no_report(doc, '/pbcoreAssetDate') { |node|
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
    
    match_no_report(doc, '/pbcoreTitle') { |node|
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

    match_no_report(doc, '/pbcoreGenre') { |node|
      @genre_type_map.map_node(node)
    }
    
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
        Cleaner.any('pbcore',
                    %w(Description Genre Relation Coverage AudienceLevel) +
                    %w(AudienceRating Creator Contributor Publisher RightsSummary)),
        REXML::Document.new('<pbcoreRightsSummary><rightsEmbedded><AAPB_RIGHTS_CODE>' \
                          'ON_LOCATION_ONLY' \
                          '</AAPB_RIGHTS_CODE></rightsEmbedded></pbcoreRightsSummary>')
      )
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

    match_no_report(doc, '/pbcoreInstantiation/instantiationDimensions/@unitOfMeasure') { |node|
      node.name = 'unitsOfMeasure'
    }

    match(doc, '/pbcoreInstantiation/instantiationMediaType' \
      '[. != "Moving Image" and . != "Sound" and . != "other"]') { |node|
      node.text = 'other'
    }

    match_no_report(doc, '/pbcoreInstantiation/instantiationLanguage') { |node|
      Cleaner.clean_language(node)
    }

    match_no_report(doc, '/pbcoreInstantiation/instantiationEssenceTrack/essenceTrackLanguage') { |node|
      Cleaner.clean_language(node)
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

  def add_report(category, instance)
    # TODO: I don't think anyone ended up using this. Confirm and delete.
    @report[category] ||= Set.new
    @report[category].add(instance)
  end

  def match(doc, xpath_fragment)
    @current_category = xpath_fragment # TODO: Is there a better way to get this into the each-scope?
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument' + xpath_fragment).each do |node|
      add_report(@current_category, @current_name)
      yield node
    end
  end

  def match_no_report(doc, xpath_fragment)
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
