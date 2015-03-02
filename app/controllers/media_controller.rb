class MediaController < ApplicationController
  
  include Blacklight::Catalog
  
  def show
    response, document = get_solr_response_for_doc_id
    xml = document.instance_variable_get('@_source')['xml']
    pbcore = PBCore.new(xml)
    
    ci = CiCore.new(credentials_path: File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
    # OAuth credentials expire: otherwise it would make sense to cache this instance.
    redirect_to ci.download(pbcore.ci_id)
  end
  
end
