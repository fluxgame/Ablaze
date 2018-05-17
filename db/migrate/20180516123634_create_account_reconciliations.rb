class CreateAccountReconciliations < ActiveRecord::Migration[5.2]
  def change
    create_table :account_reconciliations do |t|
      t.references :account, foreign_key: true
      t.float :balance, :null => false
      t.date :date, :null => false
      t.timestamps
    end
  end
end
