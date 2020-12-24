Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'home#index'

  get 'home/index'
  get 'home/signup'
  post 'home/signup'
  get 'home/logout'

  post 'home/login'

  get 'home/search'
  get 'home/users'
  get 'home/getUsers'
  post 'home/activateUser'

  get 'home/profile'
  post 'home/updateProfile'

  get 'home/getConnections'
  get 'home/getConnectionsGraph'
  get 'home/exportConnections'
  get 'home/exportConnectionsGraph'
end
