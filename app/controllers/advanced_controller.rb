require 'cgi'

class AdvancedController < ApplicationController
  def create
    redirect_to "/catalog?q=#{CGI.escape(query)}"
  end
  def query
    [
      !params[:all].empty? &&
        self.class.prefix(params[:all], '+'),
      
      !params[:title].empty? &&
        "+titles:\"#{params[:title]}\"",
      
      !params[:exact].empty? &&
        "+\"#{params[:exact]}\"",
      
      !params[:any].empty? &&
        self.class.prefix(params[:any], '', ' OR '),
      
      !params[:none].empty? &&
        self.class.prefix(params[:none], '-')
      
    ].select { |clause| clause }.join(' ')
  end
  def self.prefix(terms, prefix, joint=' ')
    terms.split(/\s+/).map { |term| "#{prefix}#{term}" }.join(joint)
  end
end
