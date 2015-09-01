require_relative '../../lib/solr'

class ApiController < ApplicationController
  def index
    @solr = Solr.instance.connect
    callback = params.delete('callback')
    rows = [params.delete('rows').to_i, 100].min
    data = @solr.get('select', params: params.except(:action, :format, :controller).merge({rows: rows}))
    respond_to do |format|
      format.json do
        pretty = JSON.pretty_generate(data)
        if callback
          render text: "#{callback}(#{pretty});"
        else
          render text: pretty;
        end
      end
      format.xml do
        render text: data.to_xml
      end
    end
  end
end
