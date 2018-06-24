class BudgetGoal < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :account
  has_many :ledger_entries
  has_many :budgeted_amounts, dependent: :destroy
  
  def remaining_amount
    return nil if self.new_record?
    (BudgetedAmount.where(budget_goal_id: self.id).sum(:amount) - LedgerEntry.where(budget_goal_id: self.id).sum('COALESCE(debit,0) - COALESCE(credit,0)')).round(user.home_asset_type.precision)
  end
end
