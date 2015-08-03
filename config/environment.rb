# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

# Monkey-patches which might be made into PRs?

module Blacklight::Solr
  class SearchBuilder < Blacklight::SearchBuilder
    def facet_value_to_fq_string(facet_field, value)
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config and facet_config.tag

      prefix = ""
      prefix = "{!#{local_params.join(" ")}}" unless local_params.empty?
      
      fq = case
        when (facet_config and facet_config.query)
          facet_config.query[value][:fq]
        when (facet_config and facet_config.date)
          # in solr 3.2+, this could be replaced by a !term query
          "#{prefix}#{facet_field}:#{RSolr.solr_escape(value)}"
        when (value.is_a?(DateTime) or value.is_a?(Date) or value.is_a?(Time))
          "#{prefix}#{facet_field}:#{RSolr.solr_escape(value.to_time.utc.strftime("%Y-%m-%dT%H:%M:%SZ"))}"
        when (value.is_a?(TrueClass) or value.is_a?(FalseClass) or value == 'true' or value == 'false'),
             (value.is_a?(Integer) or (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) or (value.to_f.to_s == value if value.respond_to? :to_f))
          "#{prefix}#{facet_field}:#{RSolr.solr_escape(value.to_s)}"
        when value.is_a?(Range)
          "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
        else
          # Before monkey-patching:
          #"{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
          # Do all the extra parts matter?
          prefix + value.split(/ OR /i).map {|single| "#{facet_field}:\"#{single}\""}.join(' ')
          # END patch
      end
    end
  end
end

module Blacklight::UrlHelperBehavior
  def add_facet_params(field, item, source_params = params)

    if item.respond_to? :field
      field = item.field
    end

    facet_config = facet_configuration_for_field(field)

    url_field = facet_config.key

    value = facet_value_for_facet_item(item)

    p = reset_search_params(source_params)
    p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$
    p[:f][url_field] = (p[:f][url_field] || []).dup

    if facet_config.single and not p[:f][url_field].empty?
      p[:f][url_field] = []
    end

    p[:f][url_field].push(value)
    # Monkey-patch:
    p[:f] = Hash[p[:f].map{|k,v| [k,[v.join(' OR ')]]}]
    # END patch
    
    if item and item.respond_to?(:fq) and item.fq
      item.fq.each do |f,v|
        p = add_facet_params(f, v, p)
      end
    end

    p
  end
end

#module Blacklight::FacetsHelperBehavior
#  def render_facet_value(facet_field, item, options ={})
#    path = search_action_path(add_facet_params_and_redirect(facet_field, item))
#    content_tag(:span, :class => "facet-label") do
#      link_to_unless(options[:suppress_link], facet_display_value(facet_field, item), path, :class=>"facet_select")
#    end + render_facet_count(item.hits)
#  end
#
#  def render_selected_facet_value(facet_field, item)
#    content_tag(:span, :class => "facet-label") do
#      content_tag(:span, facet_display_value(facet_field, item), :class => "selected") +
#      # remove link
#      link_to(content_tag(:span, '', :class => "glyphicon glyphicon-remove") + content_tag(:span, '[remove]', :class => 'sr-only'), search_action_path(remove_facet_params(facet_field, item, params)), :class=>"remove")
#    end + render_facet_count(item.hits, :classes => ["selected"])
#  end
#  
#  def render_facet_item(facet_field, item)
#    if facet_in_params?(facet_field, item.value )
#      render_selected_facet_value(facet_field, item)
#    else
#      render_facet_value(facet_field, item)
#    end
#  end
#end