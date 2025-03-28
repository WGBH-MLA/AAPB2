require_relative '../../lib/aapb'

class CatalogController < ApplicationController
  include Blacklight::Catalog
  include ApplicationHelper
  include BlacklightGUIDFetcher

  before_action :require_turnstile, only: [:index], if: -> { Rails.env.production? }

  # allows usage of default_processor_chain v
  # self.search_params_logic = true
  self.search_params_logic += [:apply_quote_handler, :apply_date_filter]

  configure_blacklight do |config|
    # 'list' is the name of blacklight's default search result view style
    config.view.gallery.partials = [:index]

    config.view.short_list.partials = [:index]
    config.view.short_list.icon_class = 'view-icon-short_list'

    # SearchBuilder contains logic for adding search params to Solr
    config.search_builder_class = SearchBuilder

    # config.view.masonry.partials = [:index]
    # config.view.masonry.icon_class = 'view-icon-masonry'

    # config.view.slideshow.partials = [:index]

    # config.show.tile_source_field = :content_metadata_image_iiif_info_ssm
    # config.show.partials.insert(1, :openseadragon)

    ## Default parameters to send to solr for all search-like requests.
    ## See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: 'search',
      rows: 10,

      # enable hit highlighting for 'text' field for transcript/caption hit compilation
      hl: true,
      :"hl.fl" => 'text'
    }

    # solr path which will be added to solr base url before the other solr params.
    # config.solr_path = 'select'

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10, 20, 50, 100]
    config.default_per_page = 20

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
    config.add_facet_field 'topics',  label: 'Topic',
                                      solr_params: { 'facet.limit' => -1 },
                                      message: 'Cataloging in progress: These tags do not reflect all AAPB content.'
    config.add_facet_field 'asset_type'
    config.add_facet_field 'states',  solr_params: { 'facet.limit' => -1 },
                                      show: false,
                                      tag: 'state'
    config.add_facet_field 'contributing_organizations', sort: 'index',
                                                         solr_params: { 'facet.limit' => -1 },
                                                         # Default is 100, but we have more orgs than that. -1 means no limit.
                                                         tag: 'org',
                                                         ex: 'org,state',
                                                         partial: 'contributing_organizations_facet',
                                                         collapse: :force
    config.add_facet_field 'producing_organizations', sort: 'index',
                                                      solr_params: { 'facet.limit' => -1 },
                                                      tag: 'producing_org',
                                                      ex: 'producing_org',
                                                      partial: 'producing_organizations_facet',
                                                      collapse: :force
    # Display all, even when one is selected.
    config.add_facet_field 'access_types',  label: 'Access',
                                            partial: 'access_facet',
                                            tag: 'access',
                                            ex: 'access',
                                            collapse: false

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
    config.add_sort_field 'asset_date desc', label: 'date (newest)'
    config.add_sort_field 'asset_date asc', label: 'date (oldest)'
    config.add_sort_field 'title asc', label: 'title'
    config.add_sort_field 'episode_number_sort asc', label: 'episode number (lowest)'
    config.add_sort_field 'episode_number_sort desc', label: 'episode number (highest)'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  def index
    # If we are looking at search results for a particular exhibit or special collection, then fetch
    # the exhibit or special collection for additional display logic.
    @exhibit = exhibit_from_url
    @special_collection = special_collection_from_url
    # Cleans up user query for manipulation of caption text in the view.

    # pull this out because we're going to mutate it inside terms_array method
    @query = params[:q].dup
    @terms_array = QueryToTermsArray.new(@query).terms_array

    if !params[:f] || !params[:f][:access_types]
      # Sets Access Level
      default_search_access(params)
    else
      super
    end

    # check whether we have enough search results to get to the page specified, if not, go to page 1
    if params[:page] && params[:page].to_i > 1
      per_page = params[:per_page] ? params[:per_page].to_i : 20

      # ensure we have enough records to fill to previous page + 1
      page = params[:page].to_i - 1
      num_for_newpage = (page * per_page) + 1

      if @response['response']['numFound'] < num_for_newpage
        params[:page] = 1
        super
      end
    end

    # mark results for captions and transcripts
    if @document_list && @document_list.first
      text_field_match_guids = @document_list.first.response['highlighting'].keys.map { |guid| normalize_guid(guid) }
    end

    # we got some dang highlit matches
    if text_field_match_guids
      @snippets = {}
      text_field_match_guids.each do |guid|
        # store a true so that we can do the ajax
        this_id = normalize_guid(guid)
        @snippets[this_id] = true
      end
    end
  end

  def show
    # From BlacklightGUIDFetcher
    id = params[:id].sub(/cpb-aacip./, "cpb-aacip?")
    @response, @document = fetch_from_solr(id)

    # If we didn't end up getting a @document, 404
    raise ActionController::RoutingError.new('Not Found') unless @document

    xml = @document['xml']
    respond_to do |format|
      format.html do
        @pbcore = PBCorePresenter.new(xml)
        @exhibits = @pbcore.top_exhibits
        @skip_orr_terms = can? :skip_tos, @pbcore

        @captions = CaptionFile.retrieve_captions(@pbcore.id)

        if can? :play, @pbcore
          # can? play because we're inside this block
          @available_and_playable = !@pbcore.media_srcs.empty? && @pbcore.outside_urls.empty?

          if redirect_to_proxy_start_time?(@pbcore, params)
            redirect_to catalog_path(params["id"], proxy_start_time: @pbcore.proxy_start_time) and return
          elsif params["start"] && params["end"] && @pbcore.media_type != "other"
            # media type: 'other' records can exist, but they shouldnt have media, so no segmenter

            media_type_verb = @pbcore.media_type == "Moving Image" ? "view" : "listen to"

            # proxy start time takes precendence, this is for 'share a segment'
            @clip_message = %(This is a segment of a longer program (#{ seconds_to_hms(params['start']) }-#{ seconds_to_hms(params['end']) }). <a href="/catalog/#{ @pbcore.id }">Click here to #{ media_type_verb } full-length item.</a>)
          end
        end

        if can? :access_transcript, @pbcore
          # If @transcript_search_term not in param, it just doesn't get populated on search input
          @transcript_search_term = params['term']
          # how shown are we talkin here?
          @transcript_open = @pbcore.correct_transcript? ? true : false
        end

        render
      end
      format.pbcore do
        render text: xml
      end
      format.mods do
        render text: PBCorePresenter.new(xml).to_mods
      end
      format.iiif do
        allow_cors!
        render json: PBCorePresenter.new(xml).iiif_manifest
      end
    end
  end

  def terms_target
    '/terms/'
  end

  private

  def require_turnstile
    return if cookies.encrypted[:turnstile_verified]
    redirect_to turnstile_challenge_path(return_to: request.fullpath)
  end

  def redirect_to_proxy_start_time?(pbcore, params)
    pbcore.proxy_start_time && params["proxy_start_time"].nil? && !media_start_time?(params)
  end

  def media_start_time?(params)
    params.keys.include?("start")
  end

  def default_search_access(params)
    base_query = params.except(:action, :controller).to_query
    access = if current_user.onsite?
               PBCorePresenter::DIGITIZED_ACCESS
             else
               PBCorePresenter::PUBLIC_ACCESS
             end
    redirect_to "/catalog?#{base_query}&f[access_types][]=#{access}"
  end

  def exhibit_from_url
    # Despite 'exhibit' field being multi-valued in solrconfig.xml, we're only
    # returning the first exhibit from the URL we currently only allow users to
    # select 1 exhibit in the UI, via the 'Show all items' link on the exhibit
    # pages are Cmless pages.
    if params['f'] && params['f']['exhibits'] && !params['f']['exhibits'].empty?
      path = params['f']['exhibits'].first
      begin
        exhibit = Exhibit.find_by_path(path)
        raise ActionController::RoutingError.new('Not Found') unless exhibit
        return exhibit
      rescue
        nil
      end
    end
  end

  def special_collection_from_url
    if params['f'] && params['f']['special_collections'] && !params['f']['special_collections'].empty?
      path = params['f']['special_collections'].first
      begin
        spec_col = SpecialCollection.find_by_path(path)
        raise ActionController::RoutingError.new('Not Found') unless spec_col
        return spec_col
      rescue
        nil
      end
    end
  end

  def allow_cors!
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end
