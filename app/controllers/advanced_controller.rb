require 'cgi'

class AdvancedController < ApplicationController
  def index
    @hidden_constraints = hidden_constraints
  end

  def create
    if params[:exact].present?
      # separate exact clause from rest of query
      qoo = "#{exactquery} #{query}"
    end
    redirect_to "/catalog?q=#{CGI.escape(qoo || query)}#{pass_constraints}"
  end

  def exactquery
    # mandatory OR query for each unstemmed field
    fieldnames = %w(captions_unstemmed
                    text_unstemmed
                    titles_unstemmed
                    contribs_unstemmed
                    title_unstemmed
                    contributing_organizations_unstemmed
                    producing_organizations_unstemmed
                    genres_unstemmed
                    topics_unstemmed
                  )
    %(+(#{fieldnames.map { |fieldname| %(#{fieldname}:"#{params[:exact]}") }.join(' OR ')}))
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

  private

  def hidden_constraints
    params[:f]
  end

  def pass_constraints
    # TODO: whitelist other parameters that we want to carry through advanced search to cat controller
    params[:f].map { |k, v| %(&f[#{k}][]=#{v}) }.join if params[:f]
  end
end
