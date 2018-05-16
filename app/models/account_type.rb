class AccountType < ApplicationRecord
  validates :name, uniqueness: true
  
  enum master_account_type: [:asset, :liability, :equity, :income, :expense]
  
  def reconcileable?
    self.master_account_type.to_sym == :asset || self.master_account_type.to_sym == :liability    
  end
end
