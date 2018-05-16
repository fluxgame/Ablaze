class AddMissingForeignKeyConstraints < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :accounts, :users
    add_foreign_key :users, :asset_types, column: :home_asset_type_id
    add_foreign_key :transactions, :users
    add_foreign_key :transactions, :transactions, column: :prototype_transaction_id
    add_foreign_key :asset_valuations, :asset_types
    add_foreign_key :asset_valuations, :asset_types, column: :valuation_asset_type_id
    add_foreign_key :ledger_entries, :accounts
    add_foreign_key :ledger_entries, :budget_goals
    add_foreign_key :ledger_entries, :transactions
    add_foreign_key :ledger_entries, :account_reconciliations
  end
end