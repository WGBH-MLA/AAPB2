require_relative '../../lib/solr'

class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  # TODO: There is nothing we have that is worth a CSRF, but CORS is a better way to do this.

  def index
    @solr = Solr.instance.connect
    callback = params.delete('callback') || 'callback'
    rows = [params.delete('rows').to_i, 100].min
    data = begin
      @solr.get('select', params: params.except(:action, :format, :controller).merge(rows: rows))
    rescue => e
      # RSolr dictates that responses be ruby data structures,
      # but the eval still scares me.
      eval(e.response[:body])
    end
    json = JSON.pretty_generate(data)
    respond_to do |format|
      format.js do
        render text: "#{callback}(#{json});",
               status: data['error'] ? 500 : 200
      end
      format.json do
        render text: json,
               status: data['error'] ? 500 : 200
      end
      format.xml do
        render text: data.to_xml,
               status: data['error'] ? 500 : 200
      end
    end
  end
end
