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
    @thumbnail_url = hash['thumbnail_url'] || "//mlamedia01.wgbh.org/aapb/featured/#{@id}_gallery.jpg"
  end

  (File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/featured.yml').tap do |path|
    @@features = YAML.load_file(path).map { |hash| Featured.new(hash) }
  end
  
  public
  
  def self.all
    @@features
  end

end
