module ToMods
  def to_mods
    Nokogiri::XML::Builder.new do |x|
      x.mods(xmlns: 'http://www.loc.gov/mods/v3') do
        x.identifier('http://americanarchive.org/catalog/' + id, type: 'uri')

        x.titleInfo(usage: 'primary') do
          x.title(title)
        end

        (creators + contributors).each do |person|
          x.name(person.name) do
            x.role do
              x.roleTerm(person.role)
            end
          end
        end

        x.typeOfResource(
          video? ? 'moving image' : 'sound recording'
        )

        x.physicalDescription do
          x.digitalOrigin('digitized other analog')
        end

        (genres + topics).each do |term|
          x.genre(term)
        end

        x.originInfo do
          publishers.each do |publisher|
            x.publisher(publisher.name)
          end
          x.dateCreated(asset_date)
        end

        x.physicalDescription do
          x.extent(duration)
        end

        x.abstract(descriptions.join("\n"))

        subjects.each do |subj|
          x.subject(subj)
        end

        x.relatedItem(type: 'host') do
          x.titleInfo do
            x.title('American Archive of Public Broadcasting')
          end
        end

        x.location do
          x.physicalLocation(organization.short_name)
          if outside_url
            x.url(outside_url, access: 'object in context', usage: 'primary')
          end
        end

        x.accessCondition('Contact host institution for more information.', type: 'use and reproduction')
      end
    end.to_xml.sub('<?xml version="1.0"?>', '')
  end
end
