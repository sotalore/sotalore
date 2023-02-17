Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users

  root to: 'home#show', as: :root
  get 'roadmap', to: 'home#roadmap'
  get 'lunar-rifts', to: 'home#lunar_rifts'
  get 'master-trainers', to: 'home#master_trainers'
  get 'incoming', to: 'home#incoming'

  resources :comments, except: [ :new, :create, :show ]
  resources :items, controller: 'items' do
    collection do
      get 'use/:use', to: 'items#by_use', as: 'by_use'
    end
    resources :comments, except: [ :new ]
  end

  resources :item_salvages, controller: 'item_salvages'

  resources :recipes do
    member do
      get 'show_partial', to: 'recipes#show_partial'
    end
    resources :comments, except: [ :new ]
    collection do
      get 'for_item/:item_id', to: 'recipes#for_item', as: :item
    end
    # collection do
    #   get ':craft_skill/:key', to: 'recipes#lookup'
    # end
  end

  resources :abstractions, only: [ :index ]

  resources :scenes do
    resources :comments, except: [ :new ]
  end

  resource :farming

  get 'skills', to: redirect('/skills/adventuring'), as: 'skills_redirect'
  get 'skills/basics', to: 'skills#basics', as: 'skills_basics'
  get 'skills/:activity', to: 'skills#index', as: 'skills', defaults: { activity: 'adventuring' }
  resources :avatars, except: [ :show ] do
    get 'skills/:activity', to: 'skills#index', as: 'skills', defaults: { activity: 'adventuring' }
    resources :skills, only: [ :update ]
  end


  resources :plantings

  resources :top_posts, path: 'chat' do
    resources :comments, except: [ :new ]
  end
  resolve("TopPost") do
    [:root]
  end


  resource :searches, path: 'search' do
    member do
      get :items
      get :global # for stimulus
    end
  end

  namespace :user, path: 'avatar' do
    resources :user_recipes, only: [ :create, :destroy ]
    resources :recipes, only: [ :index, :show ]
  end

  resource :styles, only: [ :show ]

end
