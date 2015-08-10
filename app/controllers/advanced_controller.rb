require 'uri'

class AdvancedController < ApplicationController
  def index
    redirect_to "/catalog?q=#{URI.encode(AdvancedController.query(params))}&" +
      "f[access_types][]=#{PBCore::PUBLIC_ACCESS}"
  end
  def self.query(params)
    [
      params[:all] && !params[:all].empty? ?
        params[:all] : '',
      params[:title] && !params[:title].empty? ? 
        "titles:\"#{params[:title]}\"" : '',
      params[:exact] && !params[:exact].empty? ?
        "\"#{params[:exact]}\"" : '',
      params[:any] && !params[:any].empty? ?
        "(#{params[:any].split(/\s+/).join(' OR ')})" : '',
      params[:none] && !params[:none].empty? ?
        params[:none].split(/\s+/).map { |term| "-#{term}"}.join(' ') : ''
    ].join(' ').strip
  end
end
