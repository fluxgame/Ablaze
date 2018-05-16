class MoveTransactionDateColumn < ActiveRecord::Migration[5.1]
  def change
    remove_column :transactions, :date
    add_column :ledger_entries, :date, :date
  end
end
