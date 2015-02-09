Rails.application.routes.draw do
  root to: 'home#index'
  get 'session/connect'
  get 'session/create'
  get 'session/destroy'
  get 'config' => 'config#index'
  post 'config' => 'config#index'
end
