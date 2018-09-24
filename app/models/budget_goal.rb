class BudgetGoal < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :account
  has_many :ledger_entries

  before_save :calculate_budgeted_amount
  
  def calculate_budgeted_amount
    puts "Remaining Amount: " + remaining_amount.to_s
    puts "Amount Spent: " + amount_spent.to_s
    self.budgeted_amount = remaining_amount + amount_spent
  end
  
  def remaining_amount= (value)
    @remaining_amount = value.to_f
  end
  
  def remaining_amount
    return @remaining_amount if @remaining_amount
    return nil if self.new_record?
    ((self.budgeted_amount.present? ? self.budgeted_amount : 0) - self.amount_spent).round(user.home_asset_type.precision)
  end
  
  def amount_spent
    LedgerEntry.where(budget_goal_id: self.id).sum('COALESCE(debit,0) - COALESCE(credit,0)')
  end
end
