require 'cgi'

class AdvancedController < ApplicationController
  def create

    if params[:exact].empty?
      qoo = "#{query}"
    else
      # separate exact clause from rest of query
      qoo = "#{exactquery} #{query}"
    end
    redirect_to "/catalog?q=#{CGI.escape(qoo)}"
  end

  def exactquery
    # mandatory OR query for each unstemmed field
    fieldnames = ['captions_unstemmed','text_unstemmed','titles_unstemmed','contribs_unstemmed','title_unstemmed','contributing_organizations_unstemmed','producing_organizations_unstemmed','genres_unstemmed','topics_unstemmed']
    eq=fieldnames.map.with_index {|fieldname, i| %(#{fieldname}:"#{params[:exact]}"#{i != (fieldnames.count-1) ? ' OR ' : nil})}.join
    %(+(#{eq}))
  end

  def query
    [
      !params[:all].empty? &&
        self.class.prefix(params[:all], '+'),

      !params[:title].empty? &&
        "+titles:\"#{params[:title]}\"",

      !params[:any].empty? &&
        self.class.prefix(params[:any], '', ' OR '),

      !params[:none].empty? &&
        self.class.prefix(params[:none], '-')

    ].select { |clause| clause }.join(' ')
  end

  def self.prefix(terms, prefix, joint = ' ')
    terms.split(/\s+/).map { |term| "#{prefix}#{term}" }.join(joint)
  end
end
