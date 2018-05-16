class AddAccountBalanceIdToLedgerEntries < ActiveRecord::Migration[5.1]
  def change
    rename_table :future_account_balances, :account_balances
    
#    add_reference :ledger_entries, :account_balance, index: true
    add_foreign_key :ledger_entries, :account_balances
  end
end
