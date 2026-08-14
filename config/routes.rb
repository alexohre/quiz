Rails.application.routes.draw do
  # devise_for :users
  mount ActionCable.server => '/cable'

  # devise_for :users, path: 'auth', controllers: { sessions: 'users/sessions' }, skip: [:registrations]
  devise_for :users, 
    path: 'auth', path_names: { sign_in: 'login', sign_out: 'logout' }, 
    controllers: { sessions: 'users/sessions' }, 
    skip: [:registrations]

    # To allow users to update their account, add the following:
  # as :user do
  #   get 'auth/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
  #   put 'auth' => 'devise/registrations#update', as: 'user_registration'
  # end

  post "create_user", to: "settings#create_user"
  post "update_user_password", to: "settings#update_user_password"
  delete "delete_user/:id", to: "settings#delete_user", as: :delete_user
  get 'settings/users', to: 'settings#users'
  get 'settings/analysis', to: 'settings#analysis', as: :settings_analysis
  get 'settings/analysis/church/:id', to: 'settings#church_analysis', as: :settings_church_analysis
  get 'settings/analysis/church/:id/pdf', to: 'settings#church_analysis_pdf', as: :settings_church_analysis_pdf

  # Church / Congregation Management Routes
  get 'settings/churches', to: 'settings#churches', as: :settings_churches
  post 'create_church', to: 'settings#create_church', as: :create_church
  delete 'delete_church/:id', to: 'settings#delete_church', as: :delete_church
  post 'create_representative', to: 'settings#create_representative', as: :create_representative
  delete 'delete_representative/:id', to: 'settings#delete_representative', as: :delete_representative

  # root "home"
  root "pages#home"
  
  post 'delete_data', to: 'settings#drop_db'
  get 'settings/settings', to: 'settings#settings'
  post 'settings/stage', to: 'settings#stage'
  get 'settings/upload', to: 'settings#upload'
  get 'settings/timer', to: 'settings#timer'
  post 'settings/timer', to: 'settings#timer'
  get 'settings/stage', to: 'settings#stage'
  post 'settings/uploader', to: 'settings#uploader'
  get 'login', to: 'pages#login'
  get 'scoreboard', to: 'pages#scoreboard'
  get 'recorder', to: 'pages#recorder', as: :recorder
  post 'update_score', to: 'pages#update_score', as: :update_score
  post 'skip_question', to: 'pages#skip_question', as: :skip_question
  post 'finish_question', to: 'pages#finish_question', as: :finish_question
  post 'rollback_question', to: 'pages#rollback_question', as: :rollback_question
  post 'reset_scores', to: 'pages#reset_scores', as: :reset_scores
  post 'reset', to: 'settings#reset'
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
