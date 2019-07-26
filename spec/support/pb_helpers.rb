module PBHelpers
  def just_xml(factory)
    factory.to_xml.gsub("<?xml version=\"1.0\"?>\n", '')
  end

  def new_pb(factory)
    PBCorePresenter.new(just_xml(factory))
  end
end