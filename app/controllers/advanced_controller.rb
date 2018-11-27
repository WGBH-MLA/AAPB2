require 'cgi'

class AdvancedController < ApplicationController
  def create
    # fqoo = if !params[:exact].empty?
    #   # "&fq=" + CGI.escape(%((captions_unstemmed:+"#{params[:exact]}" OR text_unstemmed:+"#{params[:exact]}" OR titles_unstemmed:+"#{params[:exact]}" OR contribs_unstemmed:+"#{params[:exact]}" OR title_unstemmed:+"#{params[:exact]}" OR contributing_organizations_unstemmed:+"#{params[:exact]}" OR producing_organizations_unstemmed:+"#{params[:exact]}" OR genres_unstemmed:+"#{params[:exact]}" OR topics_unstemmed:+"#{params[:exact]}")))
    # else
    #   ""
    # end
    # qoo = "q=#{CGI.escape(query)}"
    qoo = "q=#{query}"
    redirect_to "/catalog?#{qoo}"
  end

  def query
    fieldnames = ['captions_unstemmed','text_unstemmed','titles_unstemmed','contribs_unstemmed','title_unstemmed','contributing_organizations_unstemmed','producing_organizations_unstemmed','genres_unstemmed','topics_unstemmed']

    qooqoo = [
      !params[:all].empty? &&
        self.class.prefix(params[:all], '+'),

      !params[:title].empty? &&
        "+titles:\"#{params[:title]}\"",

      !params[:exact].empty? &&
        fieldnames.map.with_index {|fieldname, i| %(#{fieldname}:+"#{params[:exact]}"#{i != (fieldnames.count-1) ? ' OR ' : nil})}.join,

      !params[:any].empty? &&
        self.class.prefix(params[:any], '', ' OR '),

      !params[:none].empty? &&
        self.class.prefix(params[:none], '-')

    ].select { |clause| clause }.join(' ')

    %((#{qooqoo}))
  end

  def self.prefix(terms, prefix, joint = ' ')
    terms.split(/\s+/).map { |term| "#{prefix}#{term}" }.join(joint)
  end
end
