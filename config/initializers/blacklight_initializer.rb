module LoadXML
  def method_missing(method, *args, &block)
    if PBCore.instance_methods(false).include?(method)
      # TODO: PBCore was not defined soon enough. Must be a better way?
      @pbcore = Object.const_get('PBCore').new(self['xml_ssm']) unless @pbcore
      @pbcore.send(method)
    else
      super
    end
  end
end

SolrDocument.use_extension(LoadXML) { true }
# TODO: should we just be able to redefine SolrDocument the normal way?

Blacklight.secret_key = ENV['BLACKLIGHT_SECRET_KEY'] || 'not a secure key, please change'
