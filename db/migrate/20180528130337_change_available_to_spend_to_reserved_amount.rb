class ChangeAvailableToSpendToReservedAmount < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :available_to_spend, :float
    add_column :users, :reserved_amount, :float
    add_column :users, :min_balance_date, :date
  end
end
