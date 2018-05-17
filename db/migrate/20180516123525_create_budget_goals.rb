class CreateBudgetGoals < ActiveRecord::Migration[5.2]
  def change
    create_table :budget_goals do |t|
      t.string :name, :null => false
      t.references :user, foreign_key: true, :null => false

      t.timestamps
    end
  end
end
