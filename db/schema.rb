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

ActiveRecord::Schema.define(version: 20180512135849) do

  create_table "account_balances", force: :cascade do |t|
    t.integer "account_id"
    t.date "date"
    t.float "balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_balances_on_account_id"
  end

  create_table "account_reconciliations", force: :cascade do |t|
    t.integer "account_id"
    t.float "balance", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_reconciliations_on_account_id"
  end

  create_table "account_types", force: :cascade do |t|
    t.string "name", null: false
    t.integer "master_account_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.float "expected_annual_return"
    t.integer "asset_type_id", null: false
    t.integer "account_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "days_to_forecast"
    t.integer "user_id"
    t.boolean "mobile"
    t.index ["account_type_id"], name: "index_accounts_on_account_type_id"
    t.index ["asset_type_id"], name: "index_accounts_on_asset_type_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "asset_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "fetch_prices", default: false, null: false
    t.string "currency_symbol"
    t.integer "precision"
    t.index ["abbreviation"], name: "index_asset_types_on_abbreviation", unique: true
  end

  create_table "asset_valuations", force: :cascade do |t|
    t.datetime "date", null: false
    t.integer "asset_type_id", null: false
    t.float "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "valuation_asset_type_id", null: false
    t.index ["asset_type_id"], name: "index_asset_valuations_on_asset_type_id"
  end

  create_table "budget_goals", force: :cascade do |t|
    t.float "budgeted_amount", null: false
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_budget_goals_on_user_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.boolean "cleared", null: false
    t.float "debit"
    t.float "credit"
    t.integer "account_id", null: false
    t.integer "budget_goal_id"
    t.integer "transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date"
    t.integer "account_reconciliation_id"
    t.integer "account_reconciliations_id"
    t.integer "account_balance_id"
    t.index ["account_balance_id"], name: "index_ledger_entries_on_account_balance_id"
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["account_reconciliations_id"], name: "index_ledger_entries_on_account_reconciliations_id"
    t.index ["budget_goal_id"], name: "index_ledger_entries_on_budget_goal_id"
    t.index ["transaction_id"], name: "index_ledger_entries_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "repeat_frequency"
    t.integer "user_id"
    t.integer "prototype_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["prototype_transaction_id"], name: "index_transactions_on_prototype_transaction_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_settings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "setting_id", null: false
    t.string "setting_value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["setting_id"], name: "index_user_settings_on_setting_id"
    t.index ["user_id"], name: "index_user_settings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "home_asset_type_id"
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
