module PBHelpers
  def new_pb(factory)
    PBCorePresenter.new(factory.to_xml)
  end
end