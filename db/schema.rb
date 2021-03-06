# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150712151920) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "child_photos", force: :cascade do |t|
    t.string   "url"
    t.string   "caption"
    t.integer  "child_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "child_photos", ["child_id", "created_at"], name: "index_child_photos_on_child_id_and_created_at", using: :btree
  add_index "child_photos", ["child_id"], name: "index_child_photos_on_child_id", using: :btree

  create_table "children", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "gender"
    t.date     "birthdate"
  end

  add_index "children", ["user_id", "created_at"], name: "index_children_on_user_id_and_created_at", using: :btree
  add_index "children", ["user_id"], name: "index_children_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "password_digest"
    t.string   "activation_digest"
    t.boolean  "activated",         default: false
    t.datetime "activated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
    t.integer  "access",            default: 1,     null: false
    t.string   "remember_digest"
    t.string   "session_digest"
    t.string   "stripe_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

  add_foreign_key "child_photos", "children"
  add_foreign_key "children", "users"
end
