class CreateFutureAccountBalances < ActiveRecord::Migration[5.1]
  def change
    create_table :future_account_balances do |t|
      t.references :account, foreign_key: true
      t.datetime :date
      t.float :balance

      t.timestamps
    end
  end
end
