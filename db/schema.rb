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

ActiveRecord::Schema.define(version: 20151028201721) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "postgis"

  create_table "listing", force: :cascade do |t|
    t.integer  "ask",                                            null: false
    t.integer  "bedrooms",                                       null: false
    t.geometry "location", limit: {:srid=>4326, :type=>"point"}, null: false
    t.string   "title",    limit: 255,                           null: false
    t.datetime "date",                                           null: false
  end

  create_table "listings", force: :cascade do |t|
    t.geometry "location",     limit: {:srid=>4326, :type=>"point"}
    t.integer  "ask"
    t.integer  "price"
    t.string   "title"
    t.string   "address"
    t.datetime "posting_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id"
    t.integer  "survey_id"
  end

  add_index "listings", ["source_id"], name: "index_listings_on_source_id", using: :btree
  add_index "listings", ["survey_id"], name: "index_listings_on_survey_id", using: :btree

  create_table "sources", force: :cascade do |t|
    t.string   "title"
    t.string   "website"
    t.string   "script"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "surveys", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
