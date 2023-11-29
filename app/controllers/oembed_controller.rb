require_relative '../../lib/aapb'

class OembedController < CatalogController

  def show

    puts "\n\nparams = #{params}\n\n"

    render json: {
        "title": "Test",
        "type": "rich",
        "width": "640",
        "height": "480",
        "html": "<p>Blah blah blah</p>",
    }
  end
end
