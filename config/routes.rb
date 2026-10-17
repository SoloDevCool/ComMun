Rails.application.routes.draw do
  # API v1
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Auth
      post "auth/send_verification_code", to: "auth#send_verification_code"
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"
      post "auth/reset_password", to: "auth#reset_password"

      # Topics
      resources :topics, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :search
        end
        member do
          post :cool, action: "topic_cool", controller: "interactions"
          delete :cool, action: "topic_uncool", controller: "interactions"
          post :favorite, action: "favorite", controller: "interactions"
          delete :favorite, action: "unfavorite", controller: "interactions"
          post :tips, action: "tip", controller: "interactions"
          post :unlock_energy_block
        end

        # Comments
        resources :comments, only: [:index, :create, :destroy] do
          member do
            post :toggle_login_only
          end
        end

        # Polls (nested under topic for create/destroy)
        resource :poll, only: [:create, :destroy]
      end

      # Comments cool (standalone route)
      post "comments/:comment_id/cool", to: "interactions#comment_cool"
      delete "comments/:comment_id/cool", to: "interactions#comment_uncool"

      # Polls (standalone routes for vote/close/open)
      post "polls/:poll_id/vote", to: "polls#vote"
      post "polls/:poll_id/close", to: "polls#close"
      post "polls/:poll_id/open", to: "polls#open"

      # Users
      resources :users, only: [:show] do
        collection do
          get :search
        end
        member do
          post :follow
          delete :follow, action: "unfollow"
          post :block
          delete :block, action: "unblock"
        end
      end

      # Nodes
      resources :nodes, only: [:index] do
        member do
          post :follow
          delete :follow, action: "unfollow"
        end
      end

      # Profile
      resource :profile, only: [:show, :update] do
        patch :password
        get :favorites
        get :following
        get :followers
        get :blocked
        patch :privacy
      end

      # Check-in
      resource :check_in, only: [:create]

      # Notifications
      resources :notifications, only: [:index] do
        collection do
          get :unread_count
          put :read_all
        end
        member do
          put :read
        end
      end

      # Images
      resources :images, only: [:create]

      # Text Moderation
      post "text_moderation/check", to: "text_moderation#check"

      # Misc
      get "chat_groups", to: "misc#chat_groups"
      get "site_info", to: "misc#site_info"
      get "friend_links", to: "misc#friend_links"

      # Shop
      get "shop/items", to: "shop#index"
      post "shop/purchase", to: "shop#purchase"
      get "shop/purchases", to: "shop#purchases"

      # Tools / Honors / Kols
      get "tools", to: "tools#index"
      get "honors", to: "honors#index"
      get "kols", to: "kols#index"
    end
  end

  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks", registrations: "users/registrations", passwords: "users/passwords", sessions: "users/sessions" }
  devise_scope :user do
    post "send_verification_code", to: "users/registrations#send_verification_code", as: "send_verification_code", defaults: { format: :json }
    post "send_password_reset_code", to: "users/passwords#send_verification_code", as: "send_password_reset_code", defaults: { format: :json }
    get "users/oauth_invitation_code", to: "users/omniauth_callbacks#oauth_invitation_code", as: "users_oauth_invitation_code"
    post "users/verify_oauth_invitation_code", to: "users/omniauth_callbacks#verify_oauth_invitation_code", as: "users_verify_oauth_invitation_code"
  end

  # Admin dashboard
  namespace :admin do
    root to: "dashboard#index"
    post "demo_data/import", to: "demo_data#import", as: "demo_data_import"
    post "demo_data/clear", to: "demo_data#clear", as: "demo_data_clear"
    resources :login_logs, only: [:index]
    resources :cps_ad_click_logs, only: [:index]
    resources :users, only: [ :index, :update ] do
      member do
        post :ban
        post :unban
      end
      resources :node_memberships, only: [:index, :create, :destroy], controller: 'user_node_memberships'
      resources :course_permissions, only: [:index, :create, :destroy], controller: 'user_course_permissions'
    end
    resources :roles, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :operational_accounts, only: [ :index, :destroy ] do
      collection do
        post :batch_generate
        post :batch_generate_avatars
        post :batch_replace_avatars
        get :export
      end
    end
    resources :topic_operations, only: [ :index, :new, :create, :destroy ] do
      collection do
        post :ai_generate
        get :ai_status
        post :save_draft
        post :batch_destroy
      end
      member do
        get :publish_draft
      end
    end
    resources :topic_drafts, only: [ :edit, :update, :destroy ] do
      member do
        post :publish
      end
    end
    resources :auto_topics, only: [ :index ]
    post "auto_topics/trigger_now", to: "auto_topics#trigger_now", as: "auto_topics_trigger_now"
    post "auto_topics/dispatch_pending", to: "auto_topics#dispatch_pending", as: "auto_topics_dispatch_pending"
    post "auto_topics/:id/retry_task", to: "auto_topics#retry_task", as: "auto_topics_retry_task"
    resources :auto_comments, only: [ :index ]
    post "auto_comments/trigger_now", to: "auto_comments#trigger_now", as: "auto_comments_trigger_now"
    post "auto_comments/dispatch_pending", to: "auto_comments#dispatch_pending", as: "auto_comments_dispatch_pending"
    post "auto_comments/:id/retry_task", to: "auto_comments#retry_task", as: "auto_comments_retry_task"
    resources :comment_operations, only: [ :index, :new, :create, :destroy ] do
      collection do
        post :ai_generate
        get :ai_status
      end
    end
    resources :moderations, only: [ :index ] do
      member do
        patch :approve
        patch :reject
      end
      collection do
        post :batch_approve
        post :batch_reject
      end
    end
    resources :nodes, except: [ :show ] do
      collection do
        post :reorder
      end
    end
    resources :friend_links, except: [ :show ] do
      patch :settings, on: :collection
    end
    resources :chat_groups, except: [ :show ]
    resources :course_directions, except: [ :show ]
    resources :instructors, except: [ :show ]
    resources :courses, except: [ :show ] do
      resources :course_chapters, only: [:create, :update, :destroy] do
        resources :course_lessons, only: [:create, :update, :destroy]
      end
      resources :course_reviews, only: [:index, :create, :update, :destroy]
    end
    resources :invitation_codes, only: [ :index, :create, :destroy, :show ]
    resources :shop_items, except: [ :show ] do
      member do
        patch :toggle_active
      end
    end
    resources :user_emails, only: [:index] do
      collection do
        post :send_email
      end
    end
    resources :kols, except: [ :show ] do
      collection do
        post :invite
        post :import
        get :import_template
      end
    end
    resources :honors, except: [ :show ]
    get "settings", to: "settings#index"
    patch "settings", to: "settings#update"
    post "settings/migrate_images_to_cos", to: "settings#migrate_images_to_cos"
    post "settings/migrate_images_to_local", to: "settings#migrate_images_to_local"
    post "settings/rewrite_image_urls_to_proxy", to: "settings#rewrite_image_urls_to_proxy"
    post "settings/test_tms", to: "settings#test_tms"
    post "settings/verify_license", to: "settings#test_license"
    get "seo_settings", to: "seo_settings#index"
    patch "seo_settings", to: "seo_settings#update"
    get "appearance_settings", to: "appearance_settings#index"
    patch "appearance_settings", to: "appearance_settings#update"
    patch "appearance_settings/nav_order", to: "appearance_settings#update_nav_order"
    resources :cps_ads, only: [:index, :show, :create, :update, :destroy]
    resources :tool_categories, except: [ :show ]
    resources :tools, except: [ :show ]
    resources :qb_exams, except: [ :show ] do
      resources :qb_questions, except: [ :show ]
    end
    resources :qb_reviews, only: [ :index, :show ] do
      member do
        patch :approve
        patch :reject
      end
      collection do
        post :batch_approve
        post :batch_reject
      end
    end

    # 主题管理
    resources :themes, only: [ :index, :create, :edit, :update, :destroy ] do
      member do
        patch :activate
        patch :deactivate
        get :screenshot
      end
      collection do
        patch :reset
      end
    end

    # 插件管理
    resources :plugins, only: [ :index, :show, :new, :create ] do
      collection do
        post :scan_local
      end
      member do
        post :enable
        post :disable
        delete :uninstall
        patch :update_config
      end
    end

    # 插件&主题中心
    get "plugin_center", to: "plugin_center#index", as: "plugin_center"
    patch "plugin_center", to: "plugin_center#update_settings"
    post "plugin_center/install/:identifier", to: "plugin_center#install", as: "plugin_center_install"
    post "plugin_center/install_theme/:identifier", to: "plugin_center#install_theme", as: "plugin_center_install_theme"
  end

  # Chat Groups
  resources :chat_groups, only: [:index]

  # Courses
  resources :courses, only: [:index, :show] do
    member do
      get :learn
    end
  end

  # KOLs
  get "kols", to: "kols#index", as: :kols

  # Honors
  get "honors", to: "honors#index", as: :honors
  resources :honors, only: [], controller: 'honors'

  # Tools
  get "tools", to: "tools#index", as: :tools

  # Question Banks
  resources :question_banks, only: [:index, :show] do
    member do
      get :practice
      get :wrong
      post :submit
    end
    resources :questions, controller: 'qb_user_questions', only: [:new, :create]
  end

  # Topics
  resources :topics, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      post :pin
      post :unpin
      post :unlock_energy_block
    end
    resources :comments, only: [:create, :destroy] do
      member do
        post :toggle_login_only
      end
      resource :cool, controller: 'comment_cools', only: [:create, :destroy]
    end
    resource :cool, only: [:create, :destroy]
    resources :tips, only: [:create], defaults: { format: :json }
    resource :poll, only: [:create, :destroy] do
      member do
        post :vote, defaults: { format: :json }
        post :close
        post :open
      end
    end
  end
  get "nodes/:node/topics", to: "topics#index", as: :node_topics

  # Image upload
  post "upload_image", to: "images#create", as: :upload_image
  get "images/:id", to: "images#show", as: :uploaded_image

  # Tencent VOD
  get "api/vod/play_url", to: "vod#play_url", defaults: { format: :json }
  post "api/vod/delete_media", to: "vod#delete_media", defaults: { format: :json }
  get "api/vod/psign", to: "vod#psign", defaults: { format: :json }
  get "api/vod/upload_signature", to: "vod#upload_signature", defaults: { format: :json }

  # Notifications
  resources :notifications, only: [:index, :update] do
    patch :read_all, on: :collection
    get :unread_count, on: :collection, defaults: { format: :json }
  end

  # Check-in
  resource :check_in, only: [:create]

  # Shop
  resources :shop, only: [:index] do
    post :purchase, on: :collection
  end

  # Profile
  resource :profile, only: [:show, :update]

  # User public profile
  get "users/:id", to: "users#show", as: :user

  # User search (for @mentions)
  get "users/search", to: "users#search", defaults: { format: :json }

  # Follows
  post "users/:id/follow", to: "follows#create", as: :follow_user
  delete "users/:id/follow", to: "follows#destroy", as: :unfollow_user

  # Blocks
  post "users/:id/block", to: "blocks#create", as: :block_user
  delete "users/:id/block", to: "blocks#destroy", as: :unblock_user

  # Node Follows
  post "nodes/:node_id/follow", to: "node_follows#create", as: :follow_node
  delete "nodes/:node_id/follow", to: "node_follows#destroy", as: :unfollow_node

  # Favorites
  post "topics/:topic_id/favorite", to: "favorites#create", as: :topic_favorite
  delete "topics/:topic_id/favorite", to: "favorites#destroy", as: :topic_unfavorite

  # 插件公开 API
  post "plugins/:identifier/execute", to: "plugins#execute", defaults: { format: :json }

  get "pages/home"
  get "search", to: "topics#search", as: :search
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: :xml }
  get "robots.txt", to: "application#robots", defaults: { format: :text }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Redirect legacy /topic/:id to /:node/:slug
  get "topic/:id", to: redirect { |params, req|
    topic = Topic.find_by(id: params[:id].to_i)
    topic ? "/#{topic.node&.slug}/#{topic.slug}" : "/topics"
  }, status: :moved_permanently

  # Redirect legacy /topic/:id/*slug to /:node/:slug
  get "topic/:id/*slug", to: redirect { |params, req|
    topic = Topic.find_by(id: params[:id].to_i)
    topic ? "/#{topic.node&.slug}/#{topic.slug}" : "/topics"
  }, status: :moved_permanently

  # Redirect legacy /nodes/:node/:id to /:node/:slug
  get "nodes/:node/:id", to: redirect { |params, req|
    topic = Topic.find_by(id: params[:id].to_i)
    topic ? "/#{params[:node]}/#{topic.slug}" : "/topics"
  }, status: :moved_permanently

  # Defines the root path route ("/")
  RESERVED_NODE_SLUGS = %w[topics users admin pages search notifications profile check_in shop images chat_groups sitemap robots nodes kols courses tools ad question_banks honors].freeze
  get ":node/:slug", to: "topics#show", as: :node_topic, constraints: ->(req) { !RESERVED_NODE_SLUGS.include?(req.params[:node]) }
  get "ad/:id/click", to: "ad_clicks#click", as: :ad_click
  root "home#index"
end
