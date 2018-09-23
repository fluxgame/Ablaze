class LedgerEntry < ApplicationRecord
  belongs_to :account, touch: true
  belongs_to :budget_goal, optional: true, touch: true
  belongs_to :parent_transaction, :class_name => 'Transaction', foreign_key: 'transaction_id'
  belongs_to :account_reconciliation, optional: true
  belongs_to :account_balance, optional: true
  
  before_save :verify_self
  after_save :after_save
  around_destroy :do_destroy
  
  def verify_self
    if self.date.present? && self.date > Date.today
      errors.add(:date, "future transactions should be created as scheduled transaction")
    end
    
    if self.budget_goal_id.present? && self.account.spending_account?
      errors.add(:base, "budget goals shouldn't be added to spending accounts") 
    end
    
    if self.budget_goal_id.present? && self.parent_transaction.repeat_frequency.present?
      errors.add(:base, "budgeted spending can't happen in a scheduled transactions") 
    end

    throw :abort if errors.count > 0
  end
      
  def after_save
    puts ""
    puts ""
    puts ""
    puts "account_id was: " + self.account_id_was.to_s + ", account_id now: " + self.account_id.to_s
    puts ""
    puts ""
    puts ""
    invalidate_account_balances if :credit_changed? || :debit_changed? || :account_changed? || :date_changed?
    invalidate_account_balances(self.account_id_was, self.date_was) if :account_changed? || :date_changed?
  end
  
  def do_destroy
    this_account_id = self.account_id
    this_date = self.date
    
    yield

    invalidate_account_balances
  end
  
  def invalidate_account_balances(this_account_id = self.account_id, this_date = self.date)
    LedgerEntry.where('date >= ?', this_date).where(account_id: this_account_id).update_all(account_balance_id: nil)
    AccountBalance.where('date >= ?', this_date).where(account_id: this_account_id).delete_all
    ReportDatum.where('date >= ?', this_date).where(user_id: Account.find(this_account_id).user.id).delete_all
  end
  
  def readonly?
    return self.reconciled?
  end
    
  def linked_entries
    LedgerEntry.where(transaction_id: self.transaction_id).where.not(id: self.id)
  end
  
  def reconciled?
    persisted = LedgerEntry.where(id: self.id).first
    return false if persisted.nil?
    return persisted.account_reconciliation.present?
  end
  
  def debit_in(dest_asset_type)
    return nil if self.debit.nil?
    return self.debit if self.date.nil?
    return self.account.asset_type.exchange(self.debit, dest_asset_type, self.date)
  end

  def credit_in(dest_asset_type)
    return nil if self.credit.nil?
    return self.credit if self.date.nil?
    return self.account.asset_type.exchange(self.credit, dest_asset_type, self.date)
  end
  
  def amount_in(dest_asset_type = self.account.asset_type)
    _debit = debit_in(dest_asset_type)
    _credit = credit_in(dest_asset_type)
    (_debit.nil? ? 0 : _debit) - (_credit.nil? ? 0 : _credit)
  end
end


