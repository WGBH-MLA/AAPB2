require_relative '../../lib/solr'

class ApiController < ApplicationController
  def index
    @solr = Solr.instance.connect
    callback = params.delete('callback')
    rows = [params.delete('rows').to_i, 100].min
    data = begin
      @solr.get('select', params: params.except(:action, :format, :controller).merge({rows: rows}))
    rescue => e
      # RSolr dictates that responses be ruby data structures,
      # but the eval still scares me.
      eval(e.response[:body])
    end
    respond_to do |format|
      format.json do
        pretty = JSON.pretty_generate(data)
        render text: (callback ? "#{callback}(#{pretty});" : pretty), 
               status: data['error'] ? 500 : 200
      end
      format.xml do
        render text: data.to_xml,
               status: data['error'] ? 500 : 200
      end
    end
  end
end
