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

ActiveRecord::Schema.define(version: 20170801008) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attached_files", force: :cascade do |t|
    t.bigint "evidence_id", null: false
    t.string "filename", null: false
    t.binary "file", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evidence_id"], name: "index_attached_files_on_evidence_id"
  end

  create_table "banners", force: :cascade do |t|
    t.bigint "port_id", null: false
    t.string "info", null: false
    t.string "detected_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["port_id"], name: "index_banners_on_port_id"
  end

  create_table "evidences", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.bigint "host_id"
    t.bigint "port_id"
    t.bigint "vulnerability_id"
    t.string "title", null: false
    t.string "payload"
    t.string "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_evidences_on_host_id"
    t.index ["port_id"], name: "index_evidences_on_port_id"
    t.index ["site_id"], name: "index_evidences_on_site_id"
    t.index ["vulnerability_id"], name: "index_evidences_on_vulnerability_id"
  end

  create_table "hostnames", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id", "name"], name: "index_hostnames_on_host_id_and_name", unique: true
    t.index ["host_id"], name: "index_hostnames_on_host_id"
  end

  create_table "hosts", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "ip", null: false
    t.integer "test_status", default: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "ip"], name: "index_hosts_on_site_id_and_ip", unique: true
    t.index ["site_id"], name: "index_hosts_on_site_id"
  end

  create_table "ports", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.string "proto", null: false
    t.integer "no", null: false
    t.boolean "ssl"
    t.boolean "plain"
    t.string "state"
    t.string "service"
    t.string "nmap_service"
    t.string "nmap_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id", "proto", "no"], name: "index_ports_on_host_id_and_proto_and_no", unique: true
    t.index ["host_id"], name: "index_ports_on_host_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "attack_started"
    t.datetime "attack_finished"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "test_cases", force: :cascade do |t|
    t.integer "dangles"
    t.boolean "root", null: false
    t.integer "parent_id"
    t.string "name", null: false
    t.string "requires"
    t.boolean "runs_per_port"
    t.string "protocol"
    t.string "description"
    t.string "author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vulnerabilities", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "name", null: false
    t.integer "severity", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_vulnerabilities_on_site_id"
  end

  add_foreign_key "attached_files", "evidences"
  add_foreign_key "banners", "ports"
  add_foreign_key "evidences", "hosts"
  add_foreign_key "evidences", "ports"
  add_foreign_key "evidences", "sites"
  add_foreign_key "evidences", "vulnerabilities"
  add_foreign_key "hostnames", "hosts"
  add_foreign_key "hosts", "sites"
  add_foreign_key "ports", "hosts"
  add_foreign_key "test_cases", "test_cases", column: "parent_id"
  add_foreign_key "vulnerabilities", "sites"
end
