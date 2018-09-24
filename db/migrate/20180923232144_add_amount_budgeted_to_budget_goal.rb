class AddAmountBudgetedToBudgetGoal < ActiveRecord::Migration[5.2]
  def change
    add_column :budget_goals, :budgeted_amount, :float
  end
end
