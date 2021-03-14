Rails.application.routes.draw do

  ActiveAdmin.routes(self)
  devise_for :users

  root to: 'home#show', as: :root
  get 'roadmap', to: 'home#roadmap'
  get 'lunar-rifts', to: 'home#lunar_rifts'
  get 'incoming', to: 'home#incoming'

  resources :comments, except: [ :new, :create, :show ]
  resources :items, controller: 'items' do
    collection do
      get 'use/:use', to: 'items#by_use', as: 'by_use'
    end
    resources :comments, except: [ :new ]
  end
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

  namespace :adm do
    resources :users, except: [ :new, :create ]
    resources :comments, except: [ :new, :create ]
    resources :top_posts, except: [ :new ]
  end
end
