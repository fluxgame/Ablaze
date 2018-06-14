class AddAccountToBudgetGoal < ActiveRecord::Migration[5.2]
  def change
    add_reference :budget_goals, :account, foreign_key: true
  end
end
