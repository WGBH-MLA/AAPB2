require 'rexml/document'
require 'set'
require_relative '../../app/models/vocab_map'
require_relative '../../lib/formatter'

class Cleaner
  include Singleton

  def initialize
    @asset_type_map = VocabMap.for('asset')
    @date_type_map = VocabMap.for('date')
    @title_type_map = VocabMap.for('title')
    @description_type_map = VocabMap.for('description')
    @genre_type_map = VocabMap.for('genre')
    @topic_type_map = VocabMap.for('topic')
  end

  def clean(dirty_xml)
    dirty_xml.gsub!("xsi:xmlns='http://www.w3.org/2001/XMLSchema-instance'",
                    "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'")
    dirty_xml.gsub!("xmlns:xsi='xsi'", '')
    doc = REXML::Document.new(dirty_xml)

    # pbcoreAssetType:

    match(doc, '/pbcoreAssetType') do |node|
      @asset_type_map.map_node(node)
    end

    # TODO: insert assetType if not given.

    match(doc, '/pbcoreAssetDate') do |node|
      match = node.text.match(/^(\d{4})/)
      Cleaner.delete(node) unless match && match[1].to_i.between?(1900, Time.now.year)
    end

    # dateType

    match(doc, '/pbcoreAssetDate[not(@dateType)]') do |node|
      node.attributes['dateType'] = ''
    end

    @date_type_map.map_reorder_nodes(REXML::XPath.match(doc, '//pbcoreAssetDate/@dateType'))
    # TODO: sort instantiation dates? Though with multiple instantiations,
    # keeping the right date with the right instantiation might be hard.

    # pbcoreIdentifier:

    match(doc, '/pbcoreIdentifier[not(@source)]') do |node|
      node.attributes['source'] = 'unknown'
    end

    # pbcoreTitle:

    match(doc, '/pbcoreTitle[not(text())]') do |node|
      Cleaner.delete(node)
    end

    match(doc, '[not(pbcoreTitle)]') do
      # If there is a match, it's the root node, so no "node" parameter is needed.
      Cleaner.insert_after_match(
        doc,
        '/pbcoreDescriptionDocument/pbcoreIdentifier',
        REXML::Document.new('<pbcoreTitle titleType="Program">unknown</pbcoreTitle>')
      )
    end

    match(doc, '/pbcoreTitle[not(@titleType)]') do |node|
      node.attributes['titleType'] = ''
    end

    match(doc, '/pbcoreTitle') do |node|
      node.text = Cleaner.clean_title(node.text)
    end

    @title_type_map.map_reorder_nodes(
      REXML::XPath.match(doc, '//pbcoreTitle/@titleType'))

    # pbcoreDescription:

    @description_type_map.map_reorder_nodes(
      REXML::XPath.match(doc, '//pbcoreDescription/@descriptionType'))

    # pbcoreGenre:

    match(doc, '/pbcoreGenre') do |node|
      genre = @genre_type_map.map_string(node.text)
      topic = @topic_type_map.map_string(node.text)

      if !genre.empty? && topic.empty?
        node.text = genre
        node.add_attribute('annotation', 'genre')
      elsif genre.empty? && !topic.empty?
        node.text = topic
        node.add_attribute('annotation', 'topic')
      elsif !genre.empty? && !topic.empty?
        genre_node = node
        topic_node = node.clone

        genre_node.text = genre
        genre_node.add_attribute('annotation', 'genre')

        topic_node.text = topic
        topic_node.add_attribute('annotation', 'topic')

        genre_node.next_sibling = topic_node
      else
        Cleaner.delete(node)
      end
    end

    # pbcoreRelation:

    match(doc, '/pbcoreRelation[not(pbcoreRelationType)]') do |node|
      Cleaner.delete(node)
    end

    match(doc, '/pbcoreRelation') do |node|
      if node.elements[1].name == 'pbcoreRelationIdentifier'
        Cleaner.swap_children(node)
      end
    end

    # pbcoreCoverage:

    match(doc, '/pbcoreCoverage[coverageType[not(node())]]') do |node|
      Cleaner.delete(node)
    end

    match(doc, '/pbcoreCoverage/coverageType') do |node|
      node.text = node.text.capitalize
    end

    # pbcoreCreator/Contributor/Publisher:

    match(doc, '/pbcoreCreator[not(creator)]') do |node|
      Cleaner.delete(node)
    end
    match(doc, '/pbcoreContributor[not(contributor)]') do |node|
      Cleaner.delete(node)
    end
    match(doc, '/pbcorePublisher[not(publisher)]') do |node|
      Cleaner.delete(node)
    end

    # pbcoreInstantiation:

    match(doc, '/pbcoreInstantiation[not(instantiationIdentifier)]') do |node|
      node[0, 0] = REXML::Element.new('instantiationIdentifier')
    end

    match(doc, '/pbcoreInstantiation/instantiationIdentifier[not(@source)]') do |node|
      node.attributes['source'] = 'unknown'
    end

    match(doc, '/pbcoreInstantiation[not(instantiationLocation)]') do |node|
      Cleaner.insert_after_match(
        node,
        Cleaner.any('instantiation', %w(Identifier Date Dimensions Physical Digital Standard)),
        REXML::Element.new('instantiationLocation')
      )
    end

    match(doc, '/pbcoreInstantiation[not(instantiationMediaType)]') do |node|
      Cleaner.insert_after_match(
        node,
        'instantiationLocation',
        REXML::Element.new('instantiationMediaType')
      )
    end

    match(doc, '/pbcoreInstantiation/instantiationDimensions/@unitOfMeasure') do |node|
      node.name = 'unitsOfMeasure'
    end

    match(doc, '/pbcoreInstantiation/instantiationMediaType' \
      '[. != "Moving Image" and . != "Sound" and . != "other"]') do |node|
      node.text = 'other'
    end

    match(doc, '/pbcoreInstantiation/instantiationLanguage') do |node|
      Cleaner.clean_language(node)
    end

    match(doc, '/pbcoreInstantiation/instantiationEssenceTrack/essenceTrackLanguage') do |node|
      Cleaner.clean_language(node)
    end

    # duplicate value removal

    seen_values = Set.new
    ['/pbcoreTitle', '/pbcoreDescription'].each do |xpath|
      match(doc, xpath) do |node|
        # This is really just to keep us from deleting the last description
        next if REXML::XPath.match(doc, '/pbcoreDescriptionDocument' + xpath).size == 1
        if seen_values.include?(node.text)
          Cleaner.delete(node)
        else
          seen_values.add(node.text)
        end
      end
    end

    match(doc, '[not(pbcoreDescription)]') do
      raise 'No pbcoreDescription remains after removal of duplicate values'
    end

    # formatting:

    Formatter.instance.format(doc).sub("<\?xml version='1\.0' encoding='UTF-8'\?> \n", '')
    # XML declaration seems to be output with trailing space, which makes tests just a bit annoying.
    # Just stripping it should be fine.
  end

  private

  def self.clean_language(node)
    node.text = node.text[0..2].downcase # Rare problem; Works for English, but not for other languages.
    node.parent.elements.delete(node) if node.text !~ /^[a-z]{3}/
  end

  def self.clean_title(title)
    title = title.gsub(/^(.*), (a|an|the)$/i, '\2 \1')

    # check for match here so we can group the 'no words' case into the same if below
    unless title =~ /[A-Z]/ && title =~ /[a-z]/
      words = title.split(' ')
    end

    if words && words.first
      # add any terms here that you want to keep in ALL CAPS or to downcase completely
      # rubocop:disable LineLength
      allcaps = %w(USA NASA NAACP NOVA FRONTLINE AFN AG ASMW BSO CEO CMU CO CTE DCA ETV HBCU HIKI ICC II IPR ITV KAKM KBDI KCAW KCMU KDNA KEET KET KETC KEXP KEZI KFME KGNU KLPA KMED KMOS KNBA KNME KOAC KOCE KODE KOZJ KOZK KPFA KQED KRMA KSYS KTCA KUCB KUED KUHF KUNM KUOW KUSC KUSP KUT KUVO KVIE KWSO KWSU KXCI KYUK LA LICBC LSU LYMI MA MELE MIT MSU NAC NAEB NE NEA NETA NJPBA NY NYS OEB OPB OPTV ORC PSA RAETA SCETV SOEC TIU UC UCB UCTV UHF UM UNC US USA UVM UW WBAI WBEZ WBRA WCNY WCTE WDIY WEDH WEDU WEOS WERU WETA WEXT WFIU WFMU WFYI WGBH WGBY WGCU WGUC WGVU WHA WHRO WHUR WHUT WHYY WIAA WKAR WLAE WMEB WNED WNET WNYC WOJB WOSU WQED WQEJ WRFA WRNI WSIU WTIP WTIU WUFT WUMB WUNC WUSF WVIA WVIZ WWOZ WXXI WYCC WYSO WYSU YSU WQXR WRF)
      nocaps = %w(AND THE AND BUT OR FOR NOR YET AS AT BY FOR IN OF ON TO FROM)
      # rubocop:enable LineLength

      # The first word should never be downcased
      first_word = words.shift
      first_word = first_word.capitalize unless allcaps.include?(first_word) || allcaps.any? { |capword| %r{(\b|-|\\|\/\\)#{capword}(\b|-|\\|\/\\)} =~ first_word }

      formatted_words = words.map do |word|
        # does allcaps include exact capword, OR does capword appear in word surrounded by word boundary or hyphen OR has no consonants
        if allcaps.include?(word) || allcaps.any? { |capword| %r{(\b|-|\\|\/\\)#{capword}(\b|-|\\|\/\\)} =~ word } || %r{\b[^AEIOUY]+\b}i =~ word
          word
        elsif nocaps.include?(word)
          word.downcase
        else
          word.capitalize
        end
      end

      formatted_words.unshift(first_word).join(' ')
    else
      title # No change, if mix of upper and lower.
    end
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
