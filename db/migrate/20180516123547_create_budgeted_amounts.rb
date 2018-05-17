class CreateBudgetedAmounts < ActiveRecord::Migration[5.2]
  def change
    create_table :budgeted_amounts do |t|
	    t.date :date, :null => false
      t.float :amount, :null => false
      t.references :budget_goal, foreign_key: true, :null => false

      t.timestamps
    end
  end
end
