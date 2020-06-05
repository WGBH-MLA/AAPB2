require 'cgi'

class AdvancedController < ApplicationController
  def index
    @hidden_constraints = hidden_constraints
  end

  def create
    redirect_to "/catalog?q=#{CGI.escape(query)}#{pass_constraints}"
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
        self.class.prefix(params[:none], '-'),

      !params[:exact].empty? &&
        # do quotes in search_builder now
        %("#{params[:exact]}")

    ].select { |clause| clause }.join(' ')
  end

  def self.prefix(terms, prefix, joint = ' ')
    terms.split(/\s+/).map { |term| "#{prefix}#{term}" }.join(joint)
  end

  private

  def hidden_constraints
    params[:f]
  end

  def pass_constraints
    # TODO: whitelist other parameters that we want to carry through advanced search to cat controller
    params[:f].map { |k, v| %(&f[#{k}][]=#{v}) }.join if params[:f]
  end
end
