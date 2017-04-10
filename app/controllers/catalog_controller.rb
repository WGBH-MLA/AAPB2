require_relative '../../lib/aapb'

class CatalogController < ApplicationController
  include Blacklight::Catalog

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests.
    ## See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: 'search',
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10, 20, 50, 100]

    ## Default parameters to send on single-document requests to Solr.
    ## These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    # config.default_document_solr_params = {
    #  :qt => 'document',
    #  ## These are hard-coded in the blacklight 'document' requestHandler
    #  # :fl => '*',
    #  # :rows => 1
    #  # :q => '{!raw f=id v=$id}'
    # }

    #    Unused:
    #    # solr field configuration for search results/index views
    #    config.index.title_field = 'title_display'
    #    config.index.display_type_field = 'format'

    # solr field configuration for document/show views
    # config.show.title_field = 'title_display'
    # config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #

    config.add_facet_field 'media_type'
    config.add_facet_field 'genres', label: 'Genre', solr_params: { 'facet.limit' => -1 },
                                     message: 'Cataloging in progress: These tags do not reflect all AAPB content.'
    config.add_facet_field 'topics', label: 'Topic', solr_params: { 'facet.limit' => -1 },
                                     message: 'Cataloging in progress: These tags do not reflect all AAPB content.'
    config.add_facet_field 'asset_type'
    config.add_facet_field 'state', solr_params: { 'facet.limit' => -1 },
                                    show: false, tag: 'state'
    config.add_facet_field 'organization', sort: 'index', solr_params: { 'facet.limit' => -1 },
                                           # Default is 100, but we have more orgs than that. -1 means no limit.
                                           tag: 'org', ex: 'org,state',
                                           partial: 'organization_facet',
                                           collapse: :force
    # Display all, even when one is selected.
    config.add_facet_field 'year', sort: 'index', range: true,
                                   message: 'Cataloging in progress: only half of the records for digitized assets are currently dated.'
    config.add_facet_field 'access_types', label: 'Access', partial: 'access_facet',
                                           tag: 'access', ex: 'access', collapse: false

    VocabMap.for('title').authorized_names.each do |name|
      config.add_facet_field "#{name.downcase.gsub(/\s/, '_')}_titles", show: false, label: name
    end

    #    config.add_facet_field 'format', :label => 'Format'
    #    config.add_facet_field 'pub_date', :label => 'Publication Year', :single => true
    #    config.add_facet_field 'subject_topic_facet', :label => 'Topic', :limit => 20
    #    config.add_facet_field 'language_facet', :label => 'Language', :limit => true
    #    config.add_facet_field 'lc_1letter_facet', :label => 'Call Number'
    #    config.add_facet_field 'subject_geo_facet', :label => 'Region'
    #    config.add_facet_field 'subject_era_facet', :label => 'Era'
    #
    #    config.add_facet_field 'example_pivot_field', :label => 'Pivot Field', :pivot => ['format', 'language_facet']
    #
    #    config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #       :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #       :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #       :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    #    }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # config.add_index_field 'title_display', :label => 'Title'
    # --> Not used in AAPB

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    # config.add_show_field 'title_display', :label => 'Title'
    # --> Not used in AAPB

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', label: 'relevance'
    config.add_sort_field 'year desc', label: 'year (newest)'
    config.add_sort_field 'year asc', label: 'year (oldest)'
    config.add_sort_field 'title asc', label: 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def index
    # If we are looking at search results for a particular exhibit, then fetch
    # the exhibit for additional display logic.
    @exhibit = exhibit_from_url

    # Cleans up user query for manipulation of caption text in the view.
    if params[:q]
      @query_for_captions = CaptionFile.clean_query_for_captions(params[:q])
    end

    if !params[:f] || !params[:f][:access_types]
      base_query = params.except(:action, :controller).to_query
      access = if current_user.onsite?
                 PBCore::DIGITIZED_ACCESS
               else
                 PBCore::PUBLIC_ACCESS
      end
      redirect_to "/catalog?#{base_query}&f[access_types][]=#{access}"
    else
      super
    end
  end

  def show
    # TODO: do we need more of the behavior from Blacklight::Catalog?
    @response, @document = fetch(params['id'])
    xml = @document['xml']

    respond_to do |format|
      format.html do
        @pbcore = PBCore.new(xml)
        @skip_orr_terms = can? :skip_tos, @pbcore
        render
      end
      format.pbcore do
        render text: xml
      end
      format.mods do
        render text: PBCore.new(xml).to_mods
      end
    end
  end

  def terms_target
    '/terms/'
  end

  private

  # Style/GuardClause
  def exhibit_from_url
    # Despite 'exhibit' field being multi-valued in solrconfig.xml, we're only
    # returning the first exhibit from the URL we currently only allow users to
    # select 1 exhibit in the UI, via the 'Show all items' link on the exhibit
    # pages are Cmless pages.
    if params['f'] && params['f']['exhibits'] && !params['f']['exhibits'].empty? # rubocop:disable Style/GuardClause
      path = params['f']['exhibits'].first
      begin
        return Exhibit.find_by_path(path)
      rescue
        nil
      end
    end
  end
end
