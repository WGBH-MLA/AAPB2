Rails.application.routes.draw do
  root to: 'home#show'

  blacklight_for :catalog

  resources 'organizations',
            path: '/participating-orgs', # for backwards compatibility.
            constraints: { id: /.*/ }, # so periods in station IDs are acceptable.
            only: [:index, :show]

  resources 'media',
            only: [:show]
          
  ['404', '500'].each do |status_code|
    get status_code, to: "errors#show", status_code: status_code
  end

  get 'robots', to: 'robots#show'

  override_constraints = lambda { |req|
    path = req.params['path']
    path.match(OverrideController::PATH_PATTERN) && !path.match(/^rails/)
  }
  
  get '/exhibits/*path', to: 'exhibits#show', constraints: override_constraints
  
  get '/*path', to: 'override#show', constraints: override_constraints
end
