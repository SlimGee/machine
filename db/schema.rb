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

ActiveRecord::Schema[8.0].define(version: 2025_05_07_163155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vector"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

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

  create_table "assets", force: :cascade do |t|
    t.bigint "target_id", null: false
    t.text "asset_type"
    t.string "identifier"
    t.integer "criticality"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["target_id"], name: "index_assets_on_target_id"
  end

  create_table "assistants", force: :cascade do |t|
    t.string "instructions"
    t.string "tool_choice"
    t.json "tools"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "correlations", force: :cascade do |t|
    t.bigint "first_event_id", null: false
    t.bigint "second_event_id", null: false
    t.float "confidence"
    t.text "relationship_type"
    t.datetime "discovered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["first_event_id"], name: "index_correlations_on_first_event_id"
    t.index ["second_event_id"], name: "index_correlations_on_second_event_id"
  end

  create_table "event_indicators", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "indicator_id", null: false
    t.text "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["event_id"], name: "index_event_indicators_on_event_id"
    t.index ["indicator_id"], name: "index_event_indicators_on_indicator_id"
  end

  create_table "event_tactics", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "tactic_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["event_id"], name: "index_event_tactics_on_event_id"
    t.index ["tactic_id"], name: "index_event_tactics_on_tactic_id"
  end

  create_table "event_threat_actors", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "threat_actor_id", null: false
    t.float "confidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["event_id"], name: "index_event_threat_actors_on_event_id"
    t.index ["threat_actor_id"], name: "index_event_threat_actors_on_threat_actor_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "event_type"
    t.datetime "timestamp", precision: nil
    t.text "description"
    t.string "severity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tactic_id"
    t.vector "embedding"
    t.index ["tactic_id"], name: "index_events_on_tactic_id"
  end

  create_table "indicators", force: :cascade do |t|
    t.string "indicator_type"
    t.text "value"
    t.integer "confidence"
    t.datetime "first_seen"
    t.datetime "last_seen"
    t.bigint "source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "analysed", default: false, null: false
    t.vector "embedding"
    t.index ["source_id"], name: "index_indicators_on_source_id"
  end

  create_table "malicious_domains", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["name"], name: "index_malicious_domains_on_name", unique: true
  end

  create_table "malware_events", force: :cascade do |t|
    t.bigint "malware_id", null: false
    t.bigint "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["event_id"], name: "index_malware_events_on_event_id"
    t.index ["malware_id"], name: "index_malware_events_on_malware_id"
  end

  create_table "malware_indicators", force: :cascade do |t|
    t.bigint "indicator_id", null: false
    t.bigint "malware_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["indicator_id"], name: "index_malware_indicators_on_indicator_id"
    t.index ["malware_id"], name: "index_malware_indicators_on_malware_id"
  end

  create_table "malware_malicious_domains", force: :cascade do |t|
    t.bigint "malicious_domain_id", null: false
    t.bigint "malware_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["malicious_domain_id"], name: "index_malware_malicious_domains_on_malicious_domain_id"
    t.index ["malware_id"], name: "index_malware_malicious_domains_on_malware_id"
  end

  create_table "malware_threat_actors", force: :cascade do |t|
    t.bigint "malware_id", null: false
    t.bigint "threat_actor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["malware_id"], name: "index_malware_threat_actors_on_malware_id"
    t.index ["threat_actor_id"], name: "index_malware_threat_actors_on_threat_actor_id"
  end

  create_table "malwares", force: :cascade do |t|
    t.string "name"
    t.string "malware_id"
    t.string "target"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "assistant_id"
    t.string "role"
    t.text "content"
    t.json "tool_calls"
    t.string "tool_call_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assistant_id"], name: "index_messages_on_assistant_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.bigint "threat_actor_id", null: false
    t.bigint "target_id", null: false
    t.bigint "technique_id", null: false
    t.float "confidence"
    t.datetime "estimated_timeframe"
    t.datetime "predictioni_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["target_id"], name: "index_predictions_on_target_id"
    t.index ["technique_id"], name: "index_predictions_on_technique_id"
    t.index ["threat_actor_id"], name: "index_predictions_on_threat_actor_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name"
    t.string "source_type"
    t.text "url"
    t.integer "reliability"
    t.datetime "last_update"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
  end

  create_table "tactics", force: :cascade do |t|
    t.text "mitre_id"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
  end

  create_table "targets", force: :cascade do |t|
    t.string "name"
    t.string "industry"
    t.float "risk_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
  end

  create_table "techniques", force: :cascade do |t|
    t.text "mitre_id"
    t.string "name"
    t.text "description"
    t.bigint "tactic_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["mitre_id"], name: "index_techniques_on_mitre_id", unique: true
    t.index ["tactic_id"], name: "index_techniques_on_tactic_id"
  end

  create_table "threat_actor_indicators", force: :cascade do |t|
    t.bigint "threat_actor_id", null: false
    t.bigint "indicator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["indicator_id"], name: "index_threat_actor_indicators_on_indicator_id"
    t.index ["threat_actor_id"], name: "index_threat_actor_indicators_on_threat_actor_id"
  end

  create_table "threat_actors", force: :cascade do |t|
    t.text "name"
    t.text "description"
    t.datetime "first_seen"
    t.datetime "last_seen"
    t.integer "confidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "uid"
    t.string "provider"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vulnerabilities", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.text "cve_id"
    t.text "description"
    t.float "cvss_score"
    t.boolean "exploitable", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding"
    t.index ["asset_id"], name: "index_vulnerabilities_on_asset_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assets", "targets"
  add_foreign_key "correlations", "events", column: "first_event_id"
  add_foreign_key "correlations", "events", column: "second_event_id"
  add_foreign_key "event_indicators", "events"
  add_foreign_key "event_indicators", "indicators"
  add_foreign_key "event_tactics", "events"
  add_foreign_key "event_tactics", "tactics"
  add_foreign_key "event_threat_actors", "events"
  add_foreign_key "event_threat_actors", "threat_actors"
  add_foreign_key "events", "tactics"
  add_foreign_key "indicators", "sources"
  add_foreign_key "malware_events", "events"
  add_foreign_key "malware_events", "malwares"
  add_foreign_key "malware_indicators", "indicators"
  add_foreign_key "malware_indicators", "malwares"
  add_foreign_key "malware_malicious_domains", "malicious_domains"
  add_foreign_key "malware_malicious_domains", "malwares"
  add_foreign_key "malware_threat_actors", "malwares"
  add_foreign_key "malware_threat_actors", "threat_actors"
  add_foreign_key "messages", "assistants"
  add_foreign_key "predictions", "targets"
  add_foreign_key "predictions", "techniques"
  add_foreign_key "predictions", "threat_actors"
  add_foreign_key "techniques", "tactics"
  add_foreign_key "threat_actor_indicators", "indicators"
  add_foreign_key "threat_actor_indicators", "threat_actors"
  add_foreign_key "vulnerabilities", "assets"
end
