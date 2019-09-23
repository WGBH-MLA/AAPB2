class PBCoreInstantiationPresenter
  def initialize(instantiation_xml)
    # Not sure why we're using conditional logic on duration, so
    # leaving that as-is, but should probably rethink.
    @instantiation = PBCore::Instantiation.parse(instantiation_xml)
  end

  include AnnotationHelper
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
      track = @instantiation.essence_tracks.find(&:aspect_ratio)
      track.aspect_ratio if track
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
    @format ||= begin
      form = @instantiation.digital || @instantiation.physical
      form.value if form
    end
  end

  def annotations
    @annotations ||= @instantiation.annotations.select { |e| e.type != 'organization' }.map(&:value)
  end

  def display_text_fields
    @display_text ||= { identifier: identifier_display, format: format, generation: generations, color: colors, duration: duration }.compact
  end

  private

  def id_obj
    @id_obj ||= @instantiation.identifiers.first
  end
end
