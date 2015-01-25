Rails.application.routes.draw do
  root to: 'home#index'
  get 'session/connect'
  get 'session/create'
  get 'session/destroy'
end
