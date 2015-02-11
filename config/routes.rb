Rails.application.routes.draw do
  
  id_includes_periods = { id: /.*/ } # So that IDs with periods are accepted.
  
  root to: 'home#show'
  
  blacklight_for :catalog
  
  resources 'organizations', 
    constraints: id_includes_periods,
    only: [:index, :show]
  
  resources 'media',
    constraints: id_includes_periods,
    only: [:show]    
  
  get '/*path', to: 'override#show', constraints: lambda { |req| 
    path = req.params['path']
    path.match(/^[a-z\/-]+$/) && !path.match(/^rails/) 
  }

end
