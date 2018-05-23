class BudgetedAmount < ApplicationRecord
  belongs_to :budget_goal, touch: true
end