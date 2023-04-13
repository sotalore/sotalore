Rails.application.routes.draw do

  namespace :adm do
    resources :users, except: [ :show, :new, :create, :destroy ]
    resource :styles, only: [ :show ] do
      member do
        get :forms
      end
    end
  end

  devise_for :users, controllers: {
    registrations: 'users/registrations',
  }

  root to: 'home#show', as: :root
  get 'roadmap', to: 'home#roadmap'
  get 'lunar-rifts', to: 'home#lunar_rifts'
  get 'master-trainers', to: 'home#master_trainers'

  resource :time, only: [ :show ], controller: 'time'
  resource :profile, only: [ :show, :update ]
  resources :posts

  resources :comments, except: [ :new, :create ] do
    collection do
      get :moderate
    end
  end

  resources :items, controller: 'items' do
    collection do
      get 'use/:use', to: 'items#by_use', as: 'by_use'
    end
    resources :comments, except: [ :new ]
  end

  resources :item_salvages, only: [ :create, :destroy ]

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

  resource :farming, only: [ :show ]
  resource :farming_calendar, only: [ :show ]

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

  get 'search/items', to: 'searches#items', as: 'search_items'
  get 'search/global', to: 'searches#global', as: 'search_global'
  get 'search', to: 'searches#show', as: 'search'

  namespace :user, path: 'avatar' do
    resources :user_recipes, only: [ :create, :destroy ]
    resources :recipes, only: [ :index, :show ]
  end

end
