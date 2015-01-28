Rails.application.routes.draw do
  
  root :to => 'home#show'
  
  blacklight_for :catalog
  
  resources 'organizations', 
    constraints: { :id => /.*/ }, # So that IDs with periods are accepted.
    only: [:index, :show]
  
  get '/*path', to: 'override#show', constraints: lambda { |req| 
    path = req.params['path']
    path.match(/^[a-z\/-]+$/) && !path.match(/^rails/) 
  }

end
