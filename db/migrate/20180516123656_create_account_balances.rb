class CreateAccountBalances < ActiveRecord::Migration[5.2]
  def change
    create_table :account_balances do |t|
      t.references :account, foreign_key: true, :null => false
      t.date :date, :null => false
      t.float :balance, :null => false

      t.timestamps
    end
  end
end
