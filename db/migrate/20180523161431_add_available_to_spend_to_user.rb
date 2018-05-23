class AddAvailableToSpendToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :available_to_spend, :float
  end
end
