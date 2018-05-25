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

ActiveRecord::Schema.define(version: 2018_05_25_120025) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_balances", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.date "date", null: false
    t.float "balance", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_balances_on_account_id"
  end

  create_table "account_reconciliations", force: :cascade do |t|
    t.bigint "account_id"
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
    t.boolean "mobile", default: false, null: false
    t.bigint "asset_type_id", null: false
    t.bigint "account_type_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "fi_budget", default: 0.0, null: false
    t.index ["account_type_id"], name: "index_accounts_on_account_type_id"
    t.index ["asset_type_id"], name: "index_accounts_on_asset_type_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "asset_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.boolean "fetch_prices", default: false, null: false
    t.string "currency_symbol"
    t.integer "precision", default: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "asset_valuations", force: :cascade do |t|
    t.date "date", null: false
    t.bigint "asset_type_id", null: false
    t.bigint "valuation_asset_type_id", null: false
    t.float "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type_id", "date"], name: "asset_type_id_date_index", unique: true
    t.index ["asset_type_id"], name: "index_asset_valuations_on_asset_type_id"
    t.index ["valuation_asset_type_id"], name: "index_asset_valuations_on_valuation_asset_type_id"
  end

  create_table "budget_goals", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_budget_goals_on_user_id"
  end

  create_table "budgeted_amounts", force: :cascade do |t|
    t.date "date", null: false
    t.float "amount", null: false
    t.bigint "budget_goal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["budget_goal_id"], name: "index_budgeted_amounts_on_budget_goal_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.date "date"
    t.boolean "cleared", default: false, null: false
    t.float "debit"
    t.float "credit"
    t.bigint "account_id", null: false
    t.bigint "budget_goal_id"
    t.bigint "transaction_id", null: false
    t.bigint "account_reconciliation_id"
    t.bigint "account_balance_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_balance_id"], name: "index_ledger_entries_on_account_balance_id"
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["account_reconciliation_id"], name: "index_ledger_entries_on_account_reconciliation_id"
    t.index ["budget_goal_id"], name: "index_ledger_entries_on_budget_goal_id"
    t.index ["transaction_id"], name: "index_ledger_entries_on_transaction_id"
  end

  create_table "plaid_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "item_id", null: false
    t.string "access_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_plaid_items_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "description"
    t.string "repeat_frequency"
    t.bigint "user_id"
    t.bigint "prototype_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prototype_transaction_id"], name: "index_transactions_on_prototype_transaction_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "authentication_token", limit: 30
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.bigint "home_asset_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "available_to_spend"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["home_asset_type_id"], name: "index_users_on_home_asset_type_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "account_balances", "accounts"
  add_foreign_key "account_reconciliations", "accounts"
  add_foreign_key "accounts", "account_types"
  add_foreign_key "accounts", "asset_types"
  add_foreign_key "accounts", "users"
  add_foreign_key "asset_valuations", "asset_types"
  add_foreign_key "asset_valuations", "asset_types", column: "valuation_asset_type_id"
  add_foreign_key "budget_goals", "users"
  add_foreign_key "budgeted_amounts", "budget_goals"
  add_foreign_key "ledger_entries", "account_balances"
  add_foreign_key "ledger_entries", "account_reconciliations"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "budget_goals"
  add_foreign_key "ledger_entries", "transactions"
  add_foreign_key "plaid_items", "users"
  add_foreign_key "transactions", "transactions", column: "prototype_transaction_id"
  add_foreign_key "transactions", "users"
  add_foreign_key "users", "asset_types", column: "home_asset_type_id"
end
