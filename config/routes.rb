Rails.application.routes.draw do
  root to: 'home#show'

  blacklight_for :catalog

  resources 'terms',
            only: [:show, :create]

  resources 'embed', only: [:index, :show] # BL requires that there be an index.
  resources 'embed_terms', only: [:show, :create]

  resources 'organizations',
            path: '/participating-orgs', # for backwards compatibility.
            constraints: { id: /.*/ }, # so periods in station IDs are acceptable.
            only: [:index, :show]

  resources 'advanced',
            only: [:index, :create]

  resources 'thumbnails',
            only: [:show]

  resources 'media',
            only: [:show]

  resources 'captions',
            only: [:show]

  resources 'api',
            only: [:index]

  resources 'oai',
            only: [:index]

  %w(404 500).each do |status_code|
    get status_code, to: 'errors#show', status_code: status_code
  end

  get 'robots', to: 'robots#show'

  override_constraints = lambda do |req|
    path = req.params['path']
    path.match(/^[a-z0-9\/-]+$/) && !path.match(/^rails/)
  end

  # TODO: combine these into a resource?
  get '/exhibits', to: 'exhibits#index'
  get '/exhibits/*path', to: 'exhibits#show', constraints: override_constraints

  get '/*path', to: 'override#show', constraints: override_constraints
end
