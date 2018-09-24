class RemoveBudgetedAmounts < ActiveRecord::Migration[5.2]
  def change
    drop_table :budgeted_amounts
  end
end
