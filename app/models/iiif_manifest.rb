module IIIFManifest
  def iiif_manifest
    {
      "@context" => "http://iiif.io/api/presentation/3/context.json",
      "id" => "#{aapb_host}/#{id}.iiif",
      "type" => "Manifest",
      "label" => i18n_title,
      "metadata" => i18n_metadata,
      "homepage" => [{
        "id" => "#{aapb_host}/catalog/#{id}",
        "type" => "Text",
        "label" => i18n_title,
        "format" => "text/html" }],
      "summary" => i18n_description,
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
                    "id" => location,
                    "type" => (media_type == "Moving Image" ? "Video" : media_type),
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

  def i18n_title
    { "en" => [title] }
  end

  def i18n_description
    { "en" => [descriptions.first] }
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
    "#{aapb_host}/media/#{id}/download"
  end

  def aapb_host
    'https://americanarchive.org'
  end

  def media_format
    digital_instantiations.map(&:format).compact.first
  end
end
