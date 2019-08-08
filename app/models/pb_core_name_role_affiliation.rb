class PBCoreNameRoleAffiliation
  def initialize(name = nil, role = nil, affiliation = nil)
    if name
      # for testing only
      @name = name
      @role = role
      @affiliation = affiliation
    end
  end

  attr_accessor :name
  attr_accessor :role
  attr_accessor :affiliation

  def ==(other)
    self.class == other.class &&
      stem == other.stem &&
      name == other.name &&
      role == other.role &&
      affiliation == other.affiliation
  end

  def to_a
    [name, role, affiliation].select { |x| x }
  end
end
