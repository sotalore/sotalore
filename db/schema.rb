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

ActiveRecord::Schema[7.0].define(version: 2021_05_30_154335) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "avatars", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_default", default: false, null: false
    t.index ["user_id"], name: "index_avatars_on_user_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.string "subject_type"
    t.integer "subject_id"
    t.integer "author_id"
    t.integer "comment_type", default: 0, null: false
    t.text "body"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_key"
    t.boolean "visible", default: true, null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["subject_type", "subject_id"], name: "index_comments_on_subject_type_and_subject_id"
  end

  create_table "earned_skills", force: :cascade do |t|
    t.bigint "avatar_id", null: false
    t.string "skill_key", null: false
    t.integer "current", limit: 2
    t.integer "target", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["avatar_id"], name: "index_earned_skills_on_avatar_id"
  end

  create_table "ingredients", id: :serial, force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "item_id", null: false
    t.integer "count", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_ingredients_on_item_id"
    t.index ["recipe_id", "item_id"], name: "index_ingredients_on_recipe_id_and_item_id", unique: true
  end

  create_table "item_salvages", force: :cascade do |t|
    t.bigint "salvage_from_id", null: false
    t.bigint "salvage_to_id", null: false
    t.index ["salvage_from_id", "salvage_to_id"], name: "index_item_salvages_on_salvage_from_id_and_salvage_to_id", unique: true
    t.index ["salvage_to_id"], name: "index_item_salvages_on_salvage_to_id"
  end

  create_table "items", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "use", default: 0, null: false
    t.boolean "crafting_input", default: false, null: false
    t.integer "source", default: 0, null: false
    t.integer "price"
    t.string "gathering_skill"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "abstract", default: false, null: false
    t.integer "instance_id"
    t.integer "ingredients_count", default: 0, null: false
    t.integer "results_count", default: 0, null: false
    t.integer "last_confirmed_by_id"
    t.datetime "last_confirmed_at", precision: nil
    t.string "type", default: "Item", null: false
    t.jsonb "type_data", default: {}, null: false
    t.decimal "weight", precision: 6, scale: 2
    t.text "effects"
    t.text "notes"
    t.integer "salvage_as_result_count", limit: 2, default: 0, null: false
    t.integer "salvage_as_source_count", limit: 2, default: 0, null: false
  end

  create_table "pg_search_documents", id: :serial, force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.integer "searchable_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable_type_and_searchable_id"
  end

  create_table "plantings", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "seed_id", null: false
    t.boolean "greenhouse", default: false, null: false
    t.datetime "planted_at", precision: nil
    t.text "notes"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "location_type", default: 0, null: false
    t.index ["user_id"], name: "index_plantings_on_user_id"
  end

  create_table "recipes", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "craft_skill", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "recipe_key"
    t.integer "ingredients_count", default: 0, null: false
    t.integer "results_count", default: 0, null: false
    t.integer "last_confirmed_by_id"
    t.datetime "last_confirmed_at", precision: nil
    t.integer "proficiency"
    t.integer "teachable", limit: 2
  end

  create_table "results", id: :serial, force: :cascade do |t|
    t.integer "recipe_id", null: false
    t.integer "item_id", null: false
    t.integer "count", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "index_results_on_item_id"
    t.index ["recipe_id", "item_id"], name: "index_results_on_recipe_id_and_item_id", unique: true
    t.index ["recipe_id"], name: "index_results_on_recipe_id"
  end

  create_table "scenes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "level_id"
    t.integer "scene_type_id"
    t.integer "region_id"
    t.integer "parent_id"
    t.integer "sota_map_id"
    t.integer "sota_map_parent_poi_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "pvp", default: false, null: false
    t.boolean "level_plus", default: false, null: false
    t.index ["sota_map_id"], name: "index_scenes_on_sota_map_id", unique: true
    t.index ["sota_map_parent_poi_id"], name: "index_scenes_on_sota_map_parent_poi_id", unique: true
  end

  create_table "top_posts", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["key"], name: "index_top_posts_on_key", unique: true
  end

  create_table "user_recipes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "recipe_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["recipe_id"], name: "index_user_recipes_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_user_recipes_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_user_recipes_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "roles", default: [], null: false, array: true
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "avatars", "users"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "earned_skills", "avatars"
  add_foreign_key "ingredients", "items"
  add_foreign_key "ingredients", "recipes"
  add_foreign_key "item_salvages", "items", column: "salvage_from_id"
  add_foreign_key "item_salvages", "items", column: "salvage_to_id"
  add_foreign_key "items", "users", column: "last_confirmed_by_id"
  add_foreign_key "plantings", "users"
  add_foreign_key "recipes", "users", column: "last_confirmed_by_id"
  add_foreign_key "results", "items"
  add_foreign_key "results", "recipes"
  add_foreign_key "user_recipes", "recipes"
  add_foreign_key "user_recipes", "users"
end
