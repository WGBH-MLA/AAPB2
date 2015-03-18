Rails.application.routes.draw do
  root to: 'home#show'

  blacklight_for :catalog

  resources 'organizations',
            path: '/participating-orgs', # for backwards compatibility.
            constraints: { id: /.*/ }, # so periods in station IDs are acceptable.
            only: [:index, :show]

  resources 'media',
            only: [:show]

  get '/*path', to: 'override#show', constraints: lambda { |req|
    path = req.params['path']
    path.match(/^[a-z\/-]+$/) && !path.match(/^rails/)
  }
end
