# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_08_141124) do

  create_table "confirm_users", force: :cascade do |t|
    t.string "email"
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_confirm_users_on_email"
  end

  create_table "db_auth_users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_db_auth_users_on_email"
  end

  create_table "email_confirmation_users", force: :cascade do |t|
    t.string "email"
    t.boolean "email_confirmed", default: false, null: false
    t.string "email_confirmation_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_email_confirmation_users_on_email"
  end

  create_table "generic_users", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_generic_users_on_email"
    t.index ["username"], name: "index_generic_users_on_username"
  end

  create_table "slots_sessions", force: :cascade do |t|
    t.string "session"
    t.integer "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_slots_sessions_on_identifier"
    t.index ["session"], name: "index_slots_sessions_on_session"
  end

  create_table "soft_delete_users", force: :cascade do |t|
    t.string "email"
    t.boolean "soft_deleted", default: false, null: false
    t.index ["email"], name: "index_soft_delete_users_on_email"
  end

  create_table "token_users", force: :cascade do |t|
    t.string "email"
    t.index ["email"], name: "index_token_users_on_email"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.string "password_digest"
    t.boolean "soft_deleted", default: false, null: false
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "validation_users", force: :cascade do |t|
    t.string "email"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_validation_users_on_email"
    t.index ["username"], name: "index_validation_users_on_username"
  end

end
