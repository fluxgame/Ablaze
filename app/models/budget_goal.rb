class BudgetGoal < ApplicationRecord
  belongs_to :user, touch: true
  has_many :ledger_entries
  
  def remaining_amount
    Rails.cache.fetch("#{cache_key}/remaining_amount", expires_in: 15.minutes) {
      remaining_amount = budgeted_amount
    
      ledger_entries.each do |entry|
        remaining_amount -= ((entry.debit.nil? ? 0 : entry.debit) - (entry.credit.nil? ? 0 : entry.credit))
      end
    
      remaining_amount
    }
  end
end
