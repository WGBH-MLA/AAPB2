class Organization
  attr_reader :code
  attr_reader :name
  attr_reader :state
  
  private
  def initialize(code, name, state)
    @code = code
    @name = name
    @state = state
  end
  
  public
  
  @@orgs = Hash[
    [
      ['WGBH','WGBH Educational Foundation','MA']
    ].map do |params|
      [params[0],Organization.new(*params)]
    end
  ]
  
  def self.find(code)
    @@orgs[code]
  end
  
  def to_s
    "#{self.name} (#{self.state})"
  end
 
end