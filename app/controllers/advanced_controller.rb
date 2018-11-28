require 'cgi'

class AdvancedController < ApplicationController
  def create

    if params[:exact].empty?
      qoo = "#{query}"
    else
      qoo = "#{exactquery}"
    end
    # qoo = "q=#{CGI.escape(query)}"
    # qoo = %(q=+title_unstemmed:"racing")
    redirect_to "/catalog?q=#{qoo}"
  end

  def exactquery
    fieldnames = ['captions_unstemmed','text_unstemmed','titles_unstemmed','contribs_unstemmed','title_unstemmed','contributing_organizations_unstemmed','producing_organizations_unstemmed','genres_unstemmed','topics_unstemmed']
    fieldnames.map.with_index {|fieldname, i| %(+#{fieldname}:"#{params[:exact]}"#{i != (fieldnames.count-1) ? ' OR ' : nil})}.join
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
