module IIIFManifest
  def iiif_manifest
    {
      "@context" => "http://iiif.io/api/presentation/3/context.json",
      "id" => "#{aapb_host}/#{id}.iiif",
      "type" => "Manifest",
      "label" => i18n_titles,
      "metadata" => i18n_metadata,
      "homepage" => [{
        "id" => "#{aapb_host}/catalog/#{id}",
        "type" => "Text",
        "label" => i18n_titles,
        "format" => "text/html" }],
      "summary" => i18n_descriptions,
      "items" => [
        {
          "id" => "#{aapb_host}/iiif/#{id}/canvas",
          "type" => "Canvas",
          "duration" => duration_seconds,
          # height and witdth would be required for video content
          "items" => [
            {
              "id" => "#{aapb_host}/iiif/#{id}/annotationpage/1",
              "type" => "AnnotationPage",
              "items" => [
                {
                  "id" => "#{aapb_host}/iiif/#{id}/annotation/1",
                  "type" => "Annotation",
                  "motivation" => "painting",
                  "body" => {
                    "id" => location, # TODO: URI for media file, player will consume this and expect bits. Redirects ok.
                    "type" => media_type, # TODO: map to "Sound" or "Video"
                    "format" => media_format,
                    "duration" => duration_seconds # TODO: just ensure it's in seconds
                  },
                  "target" => "#{aapb_host}/iiif/canvas/1" # IMPORTANT: this has to be the ame as the 'id' property of the parent canvas
                }
              ]
            }
          ]
        }
      ]
    }.to_json
  end

  def i18n_titles
    titles.map { |title| { "en" => [title] } }
  end

  def i18n_descriptions
    descriptions.map { |description| { "en" => [description] } }
  end

  def i18n_metadata
    metadata.map do |key, value|
      {
        "label" => {
          "en" => [key]
        },
        "value" => {
          "en" => [value]
        }
      }
    end
  end

  def metadata
    { 'id' => id }
  end

  def duration_seconds
    duration.to_s.split(":").map(&:to_f).inject(0) { |a, e| a * 60 + e }.round(3)
  end

  def location
    URI.join(aapb_host, 'media', id).to_s
  end

  def aapb_host
    'https://americanarchive.org'
  end

  def media_format
    digital_instantiations.map(&:format).compact.first
  end
end
