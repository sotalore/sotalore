Rails.application.routes.draw do

  namespace :user, module: 'authentication' do
    resource :registration, only: [ :new, :create ]
    get '/need-confirmation', to: 'registrations#need_confirmation', as: :need_confirmation
    resource :confirmation, only: [ :new, :create, :show ]
    get '/resend-confirmation', to: 'confirmations#resend_confirmation', as: :resend_confirmation
    resource :password_reset, only: [ :new, :create, :edit, :update, :show ]
    resource :session, only: [ :new, :create, :destroy ] do
      get :destroy, as: :destroy
    end
    get '/oauth/:provider/callback', to: 'omniauth_callbacks#callback', as: :oauth_callback
  end

  # OAuth...
  # this route maps to the middleware, which will redirect to the provider
  direct(:user_oauth) { |provider| "/user/oauth/#{provider}" }


  namespace :adm do
    resources :users, except: [ :show, :new, :create, :destroy ]
    resource :styles, only: [ :show ] do
      member do
        get :forms
      end
    end
  end

  root to: 'home#show', as: :root
  get 'roadmap', to: 'home#roadmap'
  get 'lunar-rifts', to: 'home#lunar_rifts'
  get 'master-trainers', to: 'home#master_trainers'

  resource :time, only: [ :show ], controller: 'time'
  resource :cabalists, only: [ :show ]
  resource :profile, only: [ :show, :update ]
  resources :posts

  resources :comments, except: [ :new, :create ] do
    collection do
      get :moderate
    end
  end

  get 'verify/items', to: 'verifications#index', as: 'item_verifications', defaults: { collection: 'items' }
  patch 'verify/item/:item_id', to: 'verifications#update', as: 'verify_item'
  get 'verify/recipes', to: 'verifications#index', as: 'recipe_verifications', defaults: { collection: 'recipes' }
  patch 'verify/recipe/:recipe_id', to: 'verifications#update', as: 'verify_recipe'
  direct(:verify) { |verifiable| "/verify/#{verifiable.class.to_s.underscore}/#{verifiable.id}" }

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
    resources :posts
  end

  resource :farming, only: [ :show ]
  resource :farming_calendar, only: [ :show ]

  get 'skills', to: redirect('/skills/adventuring'), as: 'skills_redirect'
  get 'skills/basics', to: 'skills#basics', as: 'skills_basics'
  get 'skills/:activity', to: 'skills#index', as: 'skills', defaults: { activity: 'adventuring' }
  resources :avatars, except: [ :show ] do
    get 'skills/:activity', to: 'skills#index', as: 'skills', defaults: { activity: 'adventuring' }
    resources :skills, only: [ :update ] do
      member do
        patch :ignore, to: 'skills#ignore'
        patch :reveal, to: 'skills#reveal'
      end
    end
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
