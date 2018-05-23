class LedgerEntry < ApplicationRecord
  belongs_to :account, touch: true
  belongs_to :budget_goal, optional: true, touch: true
  belongs_to :parent_transaction, :class_name => 'Transaction', foreign_key: 'transaction_id'
  belongs_to :account_reconciliation, optional: true
  belongs_to :account_balance, optional: true
  
  before_save :verify_date
  after_save :after_amount_changed, :credit_changed? || :debit_changed?
  around_destroy :do_destroy
  
  def verify_date
    if self.date.present? && self.date > Date.today
      puts "future transactions should be created as scheduled transaction"
      errors.add(:date, "future transactions should be created as scheduled transaction")
      throw :abort
    end
  end
      
  def after_amount_changed
    invalidate_account_balances(self.account_id, self.date)
  end
  
  def do_destroy
    this_account_id = self.account_id
    this_date = self.date
    
    yield

    invalidate_account_balances(this_account_id, this_date)  
  end
  
  def invalidate_account_balances(account_id, date)

    LedgerEntry.where('date >= ?', self.date).where(account_id: self.account_id).update_all(account_balance_id: nil)
#    AccountBalance.includes(:ledger_entries).where(ledger_entries: {id: nil}).destroy_all
    AccountBalance.where('date >= ?', self.date).where(account_id: self.account_id).delete_all
#    ActiveRecord::Base.connection.execute("delete from account_balances where date >= '"+self.date.to_s+"' and not exists(select 1 from ledger_entries le where account_balances.id = le.account_balance_id)")
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
end


