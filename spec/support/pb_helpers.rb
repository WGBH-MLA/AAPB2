module PBHelpers
  def new_pb(factory)
    PBCorePresenter.new(factory.to_xml.gsub("<?xml version=\"1.0\"?>\n", ''))
  end
end