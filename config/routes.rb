Rails.application.routes.draw do
  
  id_glob = { id: /.*/ } # So that IDs with periods and slashes are accepted.
  
  root to: 'home#show'
  
  blacklight_for :catalog
  
  resources 'organizations',
    path: '/participating-orgs', # for backwards compatibility.
    constraints: id_glob,
    only: [:index, :show]
  
  resources 'media',
    constraints: id_glob,
    only: [:show]    
  
  get '/*path', to: 'override#show', constraints: lambda { |req| 
    path = req.params['path']
    path.match(/^[a-z\/-]+$/) && !path.match(/^rails/) 
  }

end
