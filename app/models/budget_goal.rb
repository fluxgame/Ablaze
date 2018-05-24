class BudgetGoal < ApplicationRecord
  belongs_to :user, touch: true
  has_many :ledger_entries
  has_many :budgeted_amounts, dependent: :destroy
  
  def remaining_amount
    return nil if self.new_record?
    Rails.cache.fetch("#{cache_key}/remaining_amount", expires_in: 15.minutes) {
      (BudgetedAmount.where(budget_goal_id: self.id).sum(:amount) - LedgerEntry.where(budget_goal_id: self.id).sum(:debit) - LedgerEntry.where(budget_goal_id: self.id).sum(:credit)).round(user.home_asset_type.precision)
    }
  end
end
