class CreateAccountReconciliations < ActiveRecord::Migration[5.1]
  def change
    create_table :account_reconciliations do |t|
      t.references :account, foreign_key: true
      t.float :balance, :null => false
      t.date :date, :null => false
      t.timestamps
    end

    add_column :ledger_entries, :account_reconciliation_id, :integer
    add_reference :ledger_entries, :account_reconciliations, index: true
  end
end
