Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  
  get 'settings/settings', to: 'settings#settings'
  get 'settings/upload', to: 'settings#upload'
  post 'settings/uploader', to: 'settings#uploader'
  root 'pages#home'
  get 'quiza', to: 'pages#quiz'
  get 'scoreboard', to: 'pages#scoreboard'
  get 'reset', to: 'pages#reset'
  get 'quizmaster', to: 'pages#quizmaster'
  get 'judges', to: 'pages#judges'

  resources :quiz, only: [:index, :show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
