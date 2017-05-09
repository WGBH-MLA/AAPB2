class PBCoreInstantiation
  def initialize(rexml_or_media_type, duration = nil)
    if duration
      @media_type = rexml_or_media_type
      @duration = duration
    else
      @rexml = rexml_or_media_type
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

  private

  def optional(xpath)
    match = REXML::XPath.match(@rexml, xpath).first
    match ? match.text : nil
  end
end
