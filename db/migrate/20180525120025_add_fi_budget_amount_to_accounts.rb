class AddFiBudgetAmountToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :fi_budget, :float, null: false, default: 0
  end
end
