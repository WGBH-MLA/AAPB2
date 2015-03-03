# A secret token used to encrypt user_id's in the Bookmarks#export callback URL
# functionality, for example in Refworks export of Bookmarks. In Rails 4, Blacklight
# will use the application's secret key base instead.
#

# Blacklight.secret_key = 'e664550f350a93a9027045fd880a48648345d072a0986389644dc57ba3ab69bdaa355c6c522ac2a9de63ef901e30395c3ae5dda39d7ec14f5c687c285595daff'

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
