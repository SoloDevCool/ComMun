# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_15_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "auto_comment_tasks", force: :cascade do |t|
    t.string "comment_content"
    t.integer "comment_id"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "scheduled_at", null: false
    t.date "scheduled_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "topic_id"
    t.datetime "updated_at", null: false
    t.index ["scheduled_date", "status"], name: "index_auto_comment_tasks_on_scheduled_date_and_status"
  end

  create_table "auto_topic_tasks", force: :cascade do |t|
    t.string "action", default: "draft", null: false
    t.datetime "created_at", null: false
    t.integer "draft_id"
    t.text "error_message"
    t.datetime "scheduled_at", null: false
    t.date "scheduled_date", null: false
    t.integer "status", default: 0, null: false
    t.integer "topic_id"
    t.string "topic_title"
    t.datetime "updated_at", null: false
    t.index ["scheduled_date", "status"], name: "index_auto_topic_tasks_on_scheduled_date_and_status"
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocked_id", null: false
    t.bigint "blocker_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
  end

  create_table "center_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", default: "", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false, comment: "0=publisher 1=admin"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_center_users_on_email", unique: true
  end

  create_table "chat_groups", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.integer "members_count", default: 0, null: false
    t.string "name", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "check_ins", force: :cascade do |t|
    t.date "checked_on", null: false
    t.datetime "created_at", null: false
    t.integer "points_earned", default: 10, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "checked_on"], name: "index_check_ins_on_user_id_and_checked_on", unique: true
    t.index ["user_id"], name: "index_check_ins_on_user_id"
  end

  create_table "comment_cools", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id"], name: "index_comment_cools_on_comment_id"
    t.index ["user_id", "comment_id"], name: "index_comment_cools_on_user_id_and_comment_id", unique: true
    t.index ["user_id"], name: "index_comment_cools_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.boolean "ai_generated", default: false, null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "login_only", default: false, null: false
    t.datetime "moderation_checked_at"
    t.string "moderation_keywords", default: [], array: true
    t.string "moderation_label"
    t.integer "moderation_score"
    t.string "moderation_status", default: "pass", null: false
    t.string "moderation_sub_label"
    t.bigint "parent_id"
    t.boolean "published_by_operational", default: false, null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.boolean "vip_only"
    t.index ["moderation_status"], name: "index_comments_on_moderation_status"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["published_by_operational"], name: "index_comments_on_published_by_operational"
    t.index ["topic_id"], name: "index_comments_on_topic_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "cools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["topic_id"], name: "index_cools_on_topic_id"
    t.index ["user_id", "topic_id"], name: "index_cools_on_user_id_and_topic_id", unique: true
    t.index ["user_id"], name: "index_cools_on_user_id"
  end

  create_table "cps_ad_click_logs", force: :cascade do |t|
    t.string "browser", default: ""
    t.string "city", default: ""
    t.string "country", default: ""
    t.bigint "cps_ad_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.string "isp", default: ""
    t.string "os", default: ""
    t.string "province", default: ""
    t.string "referer", default: ""
    t.datetime "updated_at", null: false
    t.string "user_agent", default: ""
    t.bigint "user_id"
    t.index ["cps_ad_id"], name: "index_cps_ad_click_logs_on_cps_ad_id"
    t.index ["created_at"], name: "index_cps_ad_click_logs_on_created_at"
    t.index ["ip_address"], name: "index_cps_ad_click_logs_on_ip_address"
    t.index ["user_id"], name: "index_cps_ad_click_logs_on_user_id"
  end

  create_table "cps_ads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image_url"
    t.boolean "is_active", default: true, null: false
    t.string "link_url", null: false
    t.integer "sort_order", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_cps_ads_on_is_active"
    t.index ["sort_order"], name: "index_cps_ads_on_sort_order"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["topic_id"], name: "index_favorites_on_topic_id"
    t.index ["user_id", "topic_id"], name: "index_favorites_on_user_id_and_topic_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followed_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "friend_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "is_active", default: true
    t.string "logo"
    t.string "name", null: false
    t.integer "sort_order", default: 0
    t.datetime "updated_at", null: false
    t.string "url", null: false
  end

  create_table "honors", force: :cascade do |t|
    t.date "awarded_at"
    t.string "certificate_image"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.integer "sort_order", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["is_active"], name: "index_honors_on_is_active"
    t.index ["sort_order"], name: "index_honors_on_sort_order"
    t.index ["user_id"], name: "index_honors_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "remote_url"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "expires_at"
    t.integer "max_uses", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "used_count", default: 0, null: false
    t.index ["code"], name: "index_invitation_codes_on_code", unique: true
    t.index ["created_by_id"], name: "index_invitation_codes_on_created_by_id"
  end

  create_table "jwt_denylist", id: false, force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "kols", force: :cascade do |t|
    t.string "avatar"
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.jsonb "platforms", default: []
    t.string "price"
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "comment_id"
    t.datetime "created_at", null: false
    t.bigint "topic_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id", "user_id"], name: "index_mentions_on_comment_id_and_user_id"
    t.index ["comment_id"], name: "index_mentions_on_comment_id"
    t.index ["topic_id", "user_id"], name: "index_mentions_on_topic_id_and_user_id"
    t.index ["topic_id"], name: "index_mentions_on_topic_id"
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "node_follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "node_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["node_id"], name: "index_node_follows_on_node_id"
    t.index ["user_id", "node_id"], name: "index_node_follows_on_user_id_and_node_id", unique: true
    t.index ["user_id"], name: "index_node_follows_on_user_id"
  end

  create_table "nodes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.text "icon"
    t.string "kind", default: "interest", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.text "tip"
    t.integer "topics_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_nodes_on_position"
    t.index ["slug"], name: "index_nodes_on_slug", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.string "notify_type", null: false
    t.boolean "read", default: false, null: false
    t.bigint "user_id", null: false
    t.index ["actor_id", "notify_type", "notifiable_id", "notifiable_type"], name: "index_notifications_unique", unique: true
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
  end

  create_table "plugins", force: :cascade do |t|
    t.string "author"
    t.jsonb "config", default: {}
    t.datetime "created_at", null: false
    t.text "description"
    t.string "homepage"
    t.jsonb "hooks", default: {}
    t.string "identifier", null: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.string "status", default: "uninstalled", null: false
    t.datetime "updated_at", null: false
    t.string "version", default: "1.0.0", null: false
    t.index ["identifier"], name: "index_plugins_on_identifier", unique: true
    t.index ["status"], name: "index_plugins_on_status"
  end

  create_table "poll_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id", null: false
    t.integer "sort_order", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0, null: false
    t.index ["poll_id"], name: "index_poll_options_on_poll_id"
  end

  create_table "polls", force: :cascade do |t|
    t.boolean "closed", default: false, null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_polls_on_topic_id", unique: true
    t.index ["topic_id"], name: "index_polls_on_topic_id_unique", unique: true
  end

  create_table "purchases", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.jsonb "delivered_data", default: {}
    t.integer "points_cost", default: 0, null: false
    t.bigint "shop_item_id", null: false
    t.string "status", default: "completed", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["shop_item_id"], name: "index_purchases_on_shop_item_id"
    t.index ["status"], name: "index_purchases_on_status"
    t.index ["user_id", "shop_item_id"], name: "index_purchases_on_user_id_and_shop_item_id"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "badge_class", default: "bg-secondary text-white", null: false, comment: "Bootstrap 徽章 class"
    t.boolean "built_in", default: false, null: false, comment: "内置角色不可删除"
    t.datetime "created_at", null: false
    t.string "key", null: false, comment: "角色标识（存入 users.role）"
    t.integer "level", default: 0, null: false, comment: "权限等级：>=50 可进后台内容管理，>=100 拥有管理员全部权限"
    t.string "name", null: false, comment: "角色显示名称"
    t.jsonb "permissions", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_key", unique: true
  end

  create_table "shop_items", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon", default: "bi-gift"
    t.string "item_type", default: "virtual", null: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.integer "sort_order", default: 0
    t.integer "stock", default: -1
    t.datetime "updated_at", null: false
  end

  create_table "site_appearances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "favicon_url"
    t.string "logo_display_mode", default: "text", null: false
    t.string "logo_url"
    t.datetime "updated_at", null: false
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "themes", force: :cascade do |t|
    t.jsonb "assets_urls", default: {}
    t.string "author"
    t.datetime "created_at", null: false
    t.string "custom_css_url"
    t.string "dark_styles_url"
    t.text "description"
    t.string "homepage"
    t.string "identifier", null: false
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.string "preview_color"
    t.string "screenshot_url"
    t.string "status", default: "installed", null: false
    t.string "styles_url"
    t.datetime "updated_at", null: false
    t.string "version", null: false
    t.index ["identifier"], name: "index_themes_on_identifier", unique: true
    t.index ["status"], name: "index_themes_on_status"
  end

  create_table "tips", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_tips_on_comment_id"
    t.index ["from_user_id"], name: "index_tips_on_from_user_id"
    t.index ["to_user_id"], name: "index_tips_on_to_user_id"
    t.index ["topic_id"], name: "index_tips_on_topic_id"
  end

  create_table "tool_categories", force: :cascade do |t|
    t.string "color", default: "#6366f1"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.integer "sort_order", default: 0
    t.datetime "updated_at", null: false
    t.index ["sort_order"], name: "index_tool_categories_on_sort_order"
  end

  create_table "tools", force: :cascade do |t|
    t.string "color", default: "#6366f1"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "icon_url"
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.string "pricing"
    t.integer "sort_order", default: 0
    t.jsonb "tags", default: []
    t.bigint "tool_category_id", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["sort_order"], name: "index_tools_on_sort_order"
    t.index ["tool_category_id"], name: "index_tools_on_tool_category_id"
  end

  create_table "topic_drafts", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.boolean "is_repost", default: false
    t.bigint "node_id", null: false
    t.string "source_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["node_id"], name: "index_topic_drafts_on_node_id"
    t.index ["user_id", "updated_at"], name: "index_topic_drafts_on_user_id_and_updated_at"
    t.index ["user_id"], name: "index_topic_drafts_on_user_id"
  end

  create_table "topic_energy_unlocks", force: :cascade do |t|
    t.integer "block_index", null: false
    t.datetime "created_at", null: false
    t.integer "energy_cost", null: false
    t.bigint "topic_id", null: false
    t.bigint "user_id", null: false
    t.index ["topic_id", "user_id", "block_index"], name: "index_topic_energy_unlocks_on_topic_user_block", unique: true
    t.index ["user_id"], name: "index_topic_energy_unlocks_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.boolean "ai_generated", default: false, null: false
    t.integer "comments_count", default: 0, null: false
    t.text "content", null: false
    t.integer "cools_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "is_repost", default: false, null: false
    t.datetime "last_reply_at"
    t.integer "last_reply_user_id"
    t.datetime "moderation_checked_at"
    t.string "moderation_keywords", default: [], array: true
    t.string "moderation_label"
    t.integer "moderation_score"
    t.string "moderation_status", default: "pass", null: false
    t.string "moderation_sub_label"
    t.bigint "node_id", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "pinned_at"
    t.boolean "published_by_operational", default: false, null: false
    t.string "slug"
    t.string "source_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.boolean "vip_only"
    t.index ["moderation_status"], name: "index_topics_on_moderation_status"
    t.index ["node_id", "updated_at"], name: "index_topics_on_node_id_and_updated_at"
    t.index ["node_id"], name: "index_topics_on_node_id"
    t.index ["pinned"], name: "index_topics_on_pinned", where: "(pinned = true)"
    t.index ["published_by_operational"], name: "index_topics_on_published_by_operational", where: "(published_by_operational = true)"
    t.index ["slug"], name: "index_topics_on_slug"
    t.index ["user_id", "created_at"], name: "index_topics_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "user_login_logs", force: :cascade do |t|
    t.string "browser"
    t.string "city", default: ""
    t.string "country", default: ""
    t.datetime "created_at", null: false
    t.string "ip_address", null: false
    t.string "isp", default: ""
    t.string "os"
    t.string "province", default: ""
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_user_login_logs_on_created_at"
    t.index ["ip_address"], name: "index_user_login_logs_on_ip_address"
    t.index ["user_id"], name: "index_user_login_logs_on_user_id"
  end

  create_table "user_node_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "joined_at", null: false
    t.bigint "node_id", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["node_id"], name: "index_user_node_memberships_on_node_id"
    t.index ["user_id", "node_id"], name: "index_user_node_memberships_on_user_id_and_node_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.text "avatar_data"
    t.datetime "ban_expires_at"
    t.string "ban_reason"
    t.datetime "banned_at"
    t.bigint "banned_by_id"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "invitation_code_id"
    t.boolean "is_operational", default: false, null: false
    t.datetime "last_seen_at"
    t.string "plaintext_password"
    t.integer "points", default: 0, null: false
    t.boolean "profile_public", default: true, null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.string "uid"
    t.integer "unread_notifications_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["ban_expires_at"], name: "index_users_on_ban_expires_at"
    t.index ["banned_at"], name: "index_users_on_banned_at"
    t.index ["banned_by_id"], name: "index_users_on_banned_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "((email)::text <> ''::text)"
    t.index ["invitation_code_id"], name: "index_users_on_invitation_code_id"
    t.index ["last_seen_at"], name: "index_users_on_last_seen_at"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["poll_option_id", "user_id"], name: "index_votes_on_poll_option_id_and_user_id", unique: true
    t.index ["poll_option_id"], name: "index_votes_on_poll_option_id"
    t.index ["user_id", "poll_option_id"], name: "index_votes_on_user_id_and_poll_option_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "check_ins", "users"
  add_foreign_key "comment_cools", "comments"
  add_foreign_key "comment_cools", "users"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "topics"
  add_foreign_key "comments", "users"
  add_foreign_key "cools", "topics"
  add_foreign_key "cools", "users"
  add_foreign_key "cps_ad_click_logs", "cps_ads"
  add_foreign_key "cps_ad_click_logs", "users"
  add_foreign_key "favorites", "topics"
  add_foreign_key "favorites", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "honors", "users"
  add_foreign_key "images", "users"
  add_foreign_key "invitation_codes", "users", column: "created_by_id"
  add_foreign_key "mentions", "comments"
  add_foreign_key "mentions", "topics"
  add_foreign_key "mentions", "users"
  add_foreign_key "node_follows", "nodes"
  add_foreign_key "node_follows", "users"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "polls", "topics", on_delete: :cascade
  add_foreign_key "purchases", "shop_items"
  add_foreign_key "purchases", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tips", "comments"
  add_foreign_key "tips", "topics"
  add_foreign_key "tips", "users", column: "from_user_id"
  add_foreign_key "tips", "users", column: "to_user_id"
  add_foreign_key "tools", "tool_categories"
  add_foreign_key "topic_drafts", "nodes"
  add_foreign_key "topic_drafts", "users"
  add_foreign_key "topics", "nodes"
  add_foreign_key "topics", "users"
  add_foreign_key "user_login_logs", "users"
  add_foreign_key "user_node_memberships", "nodes", on_delete: :cascade
  add_foreign_key "user_node_memberships", "users", on_delete: :cascade
  add_foreign_key "users", "invitation_codes"
  add_foreign_key "votes", "poll_options"
  add_foreign_key "votes", "users"
end
