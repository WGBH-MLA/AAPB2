Rails.application.routes.draw do
  root to: 'home#show'

  blacklight_for :catalog

  resources 'terms',
            only: [:show, :create]

  resources 'embed', only: [:index, :show] # BL requires that there be an index.
  match 'lite/:id', to: 'embed#lite', via: [:get]
  match 'openvault/:id', to: 'embed#openvault', via: [:get]

  resources 'embed_terms', only: [:show, :create]

  resources 'organizations',
            path: '/participating-orgs', # for backwards compatibility.
            constraints: { id: /.*/ }, # so periods in station IDs are acceptable.
            only: [:index, :show]

  resources 'advanced',
            only: [:index, :create]

  resources 'media',
            only: [:show]

  resources 'captions',
            only: [:show]

  resources 'transcripts',
            only: [:show]

  # TEMP: disabling this to not download transcript files
  # post '/snippets.json', to: "snippets#show"

  resources 'oai',
            only: [:index]

  get "/turnstile_challenge", to: "turnstile#challenge"
  post "/turnstile_verify", to: "turnstile#verify"

  get 'logs', to: 'logs#index'
  get 'logs/:log_file_name', to: 'logs#show', log_file_name: /.*/

  match 'api', to: 'api#index', via: [:get, :options]
  match 'api/:id', to: 'api#show', via: [:get, :options]
  match 'api/:id/transcript', to: 'api#transcript', via: [:get, :options], defaults: { format: :json }
  # 'via' only makes a difference when server is in production or test modes.

  %w(404 500).each do |status_code|
    get status_code, to: 'errors#show', status_code: status_code
  end

  # static file instead, no logic needed
  # get 'robots', to: 'robots#show'

  override_constraints = lambda do |req|
    path = req.params['path']
    path.match(/^[a-z0-9\/-]+$/) && !path.match(/^rails/)
  end

  get 'about-the-american-archive/newsletter', to: 'forms#newsletter'
  get 'about-the-american-archive/newsletter_thanks', to: 'forms#newsletter_thanks'
  get 'about-the-american-archive/feedback', to: 'forms#feedback'

  match 'recaptcha', to: 'forms#validate_recaptcha', via: [:post]

  get '/timelines/eotp', to: 'timelines#eotp'
  get '/a-tribute-to-jim-lehrer', to: 'jims#index'
  get '/a-tribute-to-robert-macneil', to: 'jims#robert_macneil'

  get '/exhibits', to: 'exhibits#index'
  get '/exhibits/*path', to: 'exhibits#show', constraints: override_constraints

  get '/primary_source_sets', to: 'primary_source_sets#index'
  get '/primary-source-sets', to: 'primary_source_sets#index'
  get '/primary_source_sets/*path', to: 'primary_source_sets#show', constraints: override_constraints
  get '/primary-source-sets/*path', to: 'primary_source_sets#show', constraints: override_constraints
  # Redirect for old links that were physically printed on fliers for conferences.
  get '/educator_resources', to: redirect('/primary_source_sets', status: 301)

  # old link support, must come before /special_collections
  get '/special_collections/eotp-i-interviews', to: redirect('/special_collections/eotp-interviews', status: 301)
  get '/about-the-american-archive/projects/net-catalog', to: redirect('/special_collections/net-catalog', status: 301)

  get '/special_collections', to: 'special_collections#index'
  get '/special_collections/*path', to: 'special_collections#show', constraints: override_constraints
  # support dashes too
  get '/special-collections', to: 'special_collections#index'
  get '/special-collections/*path', to: 'special_collections#show', constraints: override_constraints
  get '/plain_override/*path', to: 'plain_override#show', constraints: override_constraints

  get '/*path', to: 'override#show', constraints: override_constraints
end
