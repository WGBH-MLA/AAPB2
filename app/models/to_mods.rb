module ToMods
  def to_mods
    Nokogiri::XML::Builder.new do |x|
      x.mods(xmlns: 'http://www.loc.gov/mods/v3') do
        x.identifier('http://americanarchive.org/catalog/' + id, type: 'uri')

        x.titleInfo(usage: 'primary') do
          x.title(title)
        end

        (creators + contributors).each do |person|
          x.name do
            x.namePart(person.name)
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

        genres.each do |term|
          x.genre(term)
        end
        topics.each do |topic|
          x.subject do
            x.topic(topic)
          end
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
          x.url(outside_url, access: 'object in context', usage: 'primary') if outside_url
          x.url(img_src, access: 'preview') if img_src !~ %r{^/}
        end

        x.accessCondition('Contact host institution for more information.', type: 'use and reproduction')
      end
    end.to_xml.sub('<?xml version="1.0"?>', '').strip
  end
end
