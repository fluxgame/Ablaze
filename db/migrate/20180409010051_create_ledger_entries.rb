class CreateLedgerEntries < ActiveRecord::Migration[5.1]
  def change
    create_table :ledger_entries do |t|
      t.boolean :cleared, :null => false
      t.float :debit
      t.float :credit
      t.references :account, foreign_key: true, :null => false
      t.references :budget_goal, foreign_key: true
      t.references :transaction, foreign_key: true

      t.timestamps
    end
  end
end
