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

ActiveRecord::Schema[8.0].define(version: 2026_01_26_193038) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "classification_values", force: :cascade do |t|
    t.bigint "classification_id", null: false
    t.string "value", null: false
    t.text "description"
    t.integer "sort_order", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classification_id", "value"], name: "index_classification_values_on_classification_id_and_value", unique: true
    t.index ["classification_id"], name: "index_classification_values_on_classification_id"
  end

  create_table "classifications", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_classifications_on_code", unique: true
    t.index ["name"], name: "index_classifications_on_name", unique: true
  end

  create_table "games", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "playlist_id", null: false
    t.string "status", default: "active", null: false
    t.integer "current_track_index", default: 0
    t.integer "tracks_played", default: 0
    t.integer "tracks_revealed", default: 0
    t.jsonb "track_order", default: []
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id"], name: "index_games_on_playlist_id"
    t.index ["status"], name: "index_games_on_status"
    t.index ["user_id"], name: "index_games_on_user_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "code", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_permissions_on_code", unique: true
  end

  create_table "permissions_roles", id: false, force: :cascade do |t|
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.index ["permission_id", "role_id"], name: "index_permissions_roles_on_permission_id_and_role_id", unique: true
    t.index ["permission_id"], name: "index_permissions_roles_on_permission_id"
    t.index ["role_id"], name: "index_permissions_roles_on_role_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.string "name", null: false
    t.string "deezer_id"
    t.string "deezer_url"
    t.string "image_url"
    t.text "description"
    t.integer "tracks_count", default: 0, null: false
    t.integer "imported_tracks_count", default: 0, null: false
    t.string "import_status", default: "pending", null: false
    t.text "import_error"
    t.bigint "user_id", null: false
    t.bigint "genre_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "qr_status", default: "pending", null: false
    t.integer "qr_generated_count", default: 0, null: false
    t.text "qr_error"
    t.index ["deezer_id"], name: "index_playlists_on_deezer_id"
    t.index ["genre_id"], name: "index_playlists_on_genre_id"
    t.index ["import_status"], name: "index_playlists_on_import_status"
    t.index ["qr_status"], name: "index_playlists_on_qr_status"
    t.index ["user_id"], name: "index_playlists_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "value_type", default: "string", null: false
    t.string "group", default: "general"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group"], name: "index_settings_on_group"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.bigint "playlist_id", null: false
    t.string "deezer_id", null: false
    t.string "title", null: false
    t.string "artist_name", null: false
    t.string "album_name"
    t.string "album_cover_url"
    t.string "preview_url"
    t.integer "duration_seconds"
    t.integer "release_year"
    t.string "token", null: false
    t.boolean "qr_generated", default: false, null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "isrc", comment: "ISRC information for the track"
    t.string "deezer_album_id"
    t.datetime "preview_url_expires_at"
    t.string "qr_code_digest"
    t.index ["deezer_id"], name: "index_tracks_on_deezer_id"
    t.index ["playlist_id", "position"], name: "index_tracks_on_playlist_id_and_position"
    t.index ["playlist_id"], name: "index_tracks_on_playlist_id"
    t.index ["token"], name: "index_tracks_on_token", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password"
    t.datetime "remember_created_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "role_id"
    t.string "provider"
    t.string "uid"
    t.text "spotify_access_token"
    t.text "spotify_refresh_token"
    t.datetime "spotify_token_expires_at"
    t.string "name"
    t.string "image_url"
    t.string "spotify_product"
    t.string "spotify_country"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "classification_values", "classifications"
  add_foreign_key "games", "playlists"
  add_foreign_key "games", "users"
  add_foreign_key "permissions_roles", "permissions"
  add_foreign_key "permissions_roles", "roles"
  add_foreign_key "playlists", "classification_values", column: "genre_id"
  add_foreign_key "playlists", "users"
  add_foreign_key "tracks", "playlists"
  add_foreign_key "users", "roles"
end
