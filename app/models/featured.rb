class Featured
  attr_reader :id
  attr_reader :org_name
  attr_reader :name
  attr_reader :thumbnail_url

  private 
  
  def initialize(hash)
    @id = hash['id']
    @org_name = hash['org_name']
    @name = hash['name']
    @thumbnail_url = hash['thumbnail_url'] || "http://mlamedia01.wgbh.org/aapb/featured/#{@id}_gallery.jpg"
  end

  (File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/featured').tap do |parent_path|
    @@galleries = Hash[
      Dir["#{parent_path}/*-featured.yml"].map do |gallery_path|
        [
          gallery_path.sub(%r{.*/}, '').sub('-featured.yml', ''),
          YAML.load_file(gallery_path).map { |hash| Featured.new(hash) }
        ]
      end
    ]
  end
  
  public
  
  def self.from_gallery(gallery_name)
    @@galleries[gallery_name]
  end

end
