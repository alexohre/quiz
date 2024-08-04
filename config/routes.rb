Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  
  get 'delete_data', to: 'settings#drop_db'
  get 'settings/settings', to: 'settings#settings'
  post 'settings/stage', to: 'settings#stage'
  get 'settings/upload', to: 'settings#upload'
  get 'settings/timer', to: 'settings#timer'
  post 'settings/timer', to: 'settings#timer'
  get 'settings/stage', to: 'settings#stage'
  get 'settings/users', to: 'settings#users'
  post 'settings/uploader', to: 'settings#uploader'
  root 'pages#home'
  get 'quiza', to: 'pages#quiz'
  get 'scoreboard', to: 'pages#scoreboard'
  get 'reset', to: 'settings#reset'
  get 'quizmaster', to: 'pages#quizmaster'
  get 'judges', to: 'pages#judges'
  get 'timer', to: 'pages#timer'
  
  resources :stages, only: [:destory] do 
    member do 
      patch :activate
    end
  end
  
  # devise_for :users, path: 'auth', path_names: { sign_in: 'login', sign_out: 'logout', password: 'secret', confirmation: 'verification', unlock: 'unblock', registration: 'register', sign_up: 'cmon_let_me_in' }

  resources :quiz, only: [:index, :show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # for starting timer
  post 'start_timer', to: 'timers#start'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
