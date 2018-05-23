class AddReserveDetailsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :reserved_amount, :float
    add_column :users, :minimum_balance_date, :date
  end
end
