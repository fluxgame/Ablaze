class CreateLedgerEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :ledger_entries do |t|
      t.date :date
      t.boolean :cleared, :null => false, :default => false
      t.float :debit
      t.float :credit
      t.references :account, foreign_key: true, :null => false
      t.references :budget_goal, foreign_key: true
      t.references :transaction, foreign_key: true, :null => false
      t.references :account_reconciliation, foreign_key: true
	    t.references :account_balance, foreign_key: true

      t.timestamps
    end
  end
end
