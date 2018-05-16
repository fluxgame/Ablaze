class AddDaysOfFutureBalanceColumnToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :days_to_forecast, :integer
  end
end
