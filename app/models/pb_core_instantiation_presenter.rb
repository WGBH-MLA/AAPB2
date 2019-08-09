class PBCoreInstantiationPresenter
  def initialize(instantiation)
    # Not sure why we're using conditional logic on duration, so
    # leaving that as-is, but should probably rethink.
    @instantiation = instantiation
  end

  attr_accessor :instantiation

  def ==(other)
    self.class == other.class &&
      media_type == other.media_type &&
      duration == other.duration
  end

  def media_type
    @media_type ||= @instantiation.media_type.value if @instantiation.media_type
  end

  def duration
    @duration ||= @instantiation.duration.value if @instantiation.duration
  end

  def aspect_ratio
    @aspect_ratio ||= begin
      et = @instantiation.essence_tracks.find { |et| et.aspect_ratio }
      et.aspect_ratio if et
    end
  end

  def organization
    @organization ||= one_annotation_by_type(@instantiation.annotations, 'organization')
  end

  def identifier
    @identifier ||= id_obj.value if id_obj
  end

  def identifier_source
    @identifier_source ||= id_obj.source if id_obj
  end

  def identifier_display
    "#{identifier} (#{identifier_source})"
  end

  def generations
    @generations ||= @instantiation.generations.map(&:value).join(' ')
  end

  def colors
    @colors ||= @instantiation.colors.value if @instantiation.colors
  end

  def format
    @format ||= (@instantiation.digital || @instantiation.physical).value
  end

  def annotations
    @annotations ||= multiple_optional('instantiationAnnotation').reject { |e| e if e.attributes.values.map(&:value).include?('organization') }.map(&:text)
  end

  def display_text_fields
    @display_text ||= { identifier: identifier_display, format: format, generation: generations, color: colors, duration: duration }.compact
  end

  private

  def id_obj
    @id_obj ||= @instantiation.identifiers.first
  end
end
