class CreateBudgetGoals < ActiveRecord::Migration[5.1]
  def change
    create_table :budget_goals do |t|
      t.float :budgeted_amount, :null => false
      t.string :name, :null => false
      t.references :user, foreign_key: true, :null => false

      t.timestamps
    end
  end
end
