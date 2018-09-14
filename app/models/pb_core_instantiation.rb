class PBCoreInstantiation
  def initialize(rexml_or_media_type, duration = nil)
    # Not sure why we're using conditional logic on duration, so
    # leaving that as-is, but should probably rethink.
    if duration
      @media_type = rexml_or_media_type
      @duration = duration
    else
      @rexml = rexml_or_media_type
      @organization = organization
      @identifier = identifier
      @identifier_source = identifier_source
    end
  end

  def ==(other)
    self.class == other.class &&
      media_type == other.media_type &&
      duration == other.duration
  end

  def media_type
    @media_type ||= optional('instantiationMediaType')
  end

  def duration
    @duration ||= optional('instantiationDuration')
  end

  def aspect_ratio
    @aspect_ratio ||= optional('instantiationEssenceTrack/essenceTrackAspectRatio')
  end

  def organization
    @organization ||= annotation_element('organization')
  end

  def identifier
    @identifier ||= optional('instantiationIdentifier')
  end

  def identifier_source
    @identifier_source ||= optional_element_attribute('instantiationIdentifier', 'source')
  end

  def identifier_display
    "#{identifier} (#{identifier_source})"
  end

  def generations
    @generations ||= optional('instantiationGenerations')
  end

  def colors
    @colors ||= optional('instantiationColors')
  end

  def format
    @format ||= read_format
  end

  def annotations
    @annotations ||= multiple_optional('instantiationAnnotation').reject { |e| e if e.attributes.values.map(&:value).include?('organization') }.map(&:text)
  end

  def display_text_fields
    @display_text ||= { identifier: identifier_display, format: format, generation: generations, color: colors, duration: duration }.compact
  end

  private

  def optional(xpath)
    match = REXML::XPath.match(@rexml, xpath).first
    match ? match.text : nil
  end

  def multiple_optional(xpath)
    matches = REXML::XPath.match(@rexml, xpath)
    matches ? matches : nil
  end

  def annotation_element(type)
    optional("instantiationAnnotation[@annotationType=\"#{type}\"]")
  end

  def optional_element_attribute(xpath, attribute)
    match = REXML::XPath.match(@rexml, xpath).first.attributes[attribute.to_s]
    match ? match : nil
  end

  def read_format
    return optional('instantiationDigital') unless optional('instantiationDigital').nil?
    return optional('instantiationPhysical') unless optional('instantiationPhysical').nil?
    nil
  end
end
