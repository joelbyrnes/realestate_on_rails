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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120508093836) do

  create_table "inspections", :force => true do |t|
    t.datetime "start"
    t.datetime "end"
    t.string   "note"
    t.integer  "property_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "timezone",    :default => "Brisbane"
  end

  create_table "properties", :force => true do |t|
    t.string   "title"
    t.string   "external_id",                  :null => false
    t.string   "url"
    t.string   "photo_url"
    t.string   "address"
    t.date     "seen_date"
    t.string   "display_price"
    t.string   "note"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "rating",        :default => 0
  end

  add_index "properties", ["external_id"], :name => "index_properties_on_external_id", :unique => true

end
