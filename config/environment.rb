# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

module AAPB
  QUERY_OR = ' OR '
end

# Monkey-patches which might be made into PRs?

module Blacklight::Solr
  class SearchBuilder < Blacklight::SearchBuilder
    def facet_value_to_fq_string(facet_field, value)
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag

      prefix = ''
      prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?

      fq = case
           when (facet_config and facet_config.query)
             facet_config.query[value][:fq]
           when (facet_config and facet_config.date)
          # in solr 3.2+, this could be replaced by a !term query
             "#{prefix}#{facet_field}:#{RSolr.solr_escape(value)}"
           when (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
             "#{prefix}#{facet_field}:#{RSolr.solr_escape(value.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ'))}"
           when (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
             "#{prefix}#{facet_field}:#{RSolr.solr_escape(value.to_s)}"
           when value.is_a?(Range)
             "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
           else
          # Before monkey-patching:
          # "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
          # Do all the extra parts matter?
          # BEGIN patch replace
             prefix + value.split(AAPB::QUERY_OR).map { |single| "#{facet_field}:\"#{single}\"" }.join(' ')
          # END patch
      end
    end
  end
end

module Blacklight::UrlHelperBehavior
  def add_facet_params(field, item, source_params=params)
    field = item.field if item.respond_to? :field

    facet_config = facet_configuration_for_field(field)

    url_field = facet_config.key

    value = facet_value_for_facet_item(item)

    p = reset_search_params(source_params)
    p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$
    p[:f][url_field] = (p[:f][url_field] || []).dup

    p[:f][url_field] = [] if facet_config.single and not p[:f][url_field].empty?

    p[:f][url_field].push(value)
    # BEGIN patch addition:
    p[:f] = Hash[p[:f].map { |k, v| [k, [v.join(AAPB::QUERY_OR)]] }]
    # END patch

    if item and item.respond_to?(:fq) and item.fq
      item.fq.each do |f, v|
        p = add_facet_params(f, v, p)
      end
    end

    p
  end
  
  def remove_facet_params(field, item, source_params=params)
    if item.respond_to? :field
      field = item.field
    end

    facet_config = facet_configuration_for_field(field)

    url_field = facet_config.key

    value = facet_value_for_facet_item(item)

    p = reset_search_params(source_params)
    # need to dup the facet values too,
    # if the values aren't dup'd, then the values
    # from the session will get remove in the show view...
    p[:f] = (p[:f] || {}).dup
    p[:f][url_field] = (p[:f][url_field] || []).dup
    p[:f][url_field] = p[:f][url_field] - [value]
    # The line above removes an exact match (ie in the filter list).
    # The line below removes just one term (ie in the side bar).
    # BEGIN patch addition
    p[:f][url_field] = (p[:f][url_field].map{ |field| field.split(AAPB::QUERY_OR)}.map { |terms| terms - [value] }).map { |terms| terms.join(' OR ') }
    # END patch
    p[:f].delete(url_field) if p[:f][url_field].size == 0
    p.delete(:f) if p[:f].empty?
    p
  end
end

module Blacklight::FacetsHelperBehavior
  def facet_in_params?(field, item)
    if item and item.respond_to? :field
      field = item.field
    end

    value = facet_value_for_facet_item(item)

    params[:f] and params[:f][field] and
      # Before:
      #   params[:f][field].include?(value)
      # BEGIN patch replace
      params[:f][field].any? { |field| field.split(AAPB::QUERY_OR).include?(value) }
      # END patch
  end
end
