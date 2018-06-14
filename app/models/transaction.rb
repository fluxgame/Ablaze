class Transaction < ApplicationRecord
  belongs_to :user, touch: true
  
  has_many :transaction_copies, class_name: "Transaction",
                            foreign_key: "prototype_transaction_id"
  belongs_to :prototype_transaction, class_name: "Transaction", optional: true

  has_many :ledger_entries, dependent: :destroy, inverse_of: :parent_transaction
  accepts_nested_attributes_for :ledger_entries, allow_destroy: true
  
  nilify_blanks :only => [:repeat_frequency]

  validate :repeat_frequency_is_valid
  validate :verify_ledger_entries
  
  before_destroy :verify_not_reconciled
  
  def verify_ledger_entries
    if ledger_entries.size < 2
      errors.add(:base, "at least two ledger entries are required")
      throw :abort
    end
    
    if !repeat_frequency.blank? && self.asset_types.count > 1
      errors.add(:base, "asset types must be the same for a scheduled transaction")
    end
    
    if !balanced?
      errors.add(:base, "credits and debits are out of balance")
    end
    
    contains_budgeted_expense = false
    contains_non_spending_account = false
    active_ledger_entries.each do |le|
      if le.budget_goal_id.present?
        contains_budgeted_expense = true
      elsif le.account.account_type.master_account_type != :expense && !le.account.spending_account?
        contains_non_spending_account = true if le.account.account_type
      end
    end
    
    if contains_budgeted_expense && contains_non_spending_account
      errors.add(:base, "budgeted spending should only happen from spending accounts")
    end
  end
  
  def verify_not_reconciled
    active_ledger_entries.each do |le|
      if le.reconciled?
        errors.add(:base, "can't delete a transaction with reconciled entries")
        throw :abort
      end
    end
  end

  def schedule
    return @schedule if !@schedule.nil?
    if !self[:repeat_frequency].nil?
      @schedule = IceCube::Schedule.from_yaml(self[:repeat_frequency])
    else
      nil
    end
  end
  
  def create_next_occurence
    sch = self.schedule
    if !sch.nil?
      next_dates = sch.first(2)
            
      if next_dates[0].present? && next_dates[0] < Date.today + 1.day
        if next_dates.count == 1
          self.repeat_frequency = nil
          self.save

          self.ledger_entries.each do |le|
            le.date = next_dates[0]
            le.save
          end
        else
          next_date = next_dates[0]

          newt = Transaction.new description: self.description, prototype_transaction_id: self.id, user_id: self.user_id
        
          self.active_ledger_entries.each do |le|
            newt.ledger_entries.push(LedgerEntry.new date: next_date, debit: le.debit, credit: le.credit, 
                cleared: false, account_id: le.account_id, budget_goal_id: le.budget_goal_id)
          end
          
          newt.save
                
          sch.start_time = next_date + 1.day
          self.repeat_frequency = sch.to_yaml
          self.save

          self.create_next_occurence
        end
      end
    end
  end
  
  def master_ledger_entry
    LedgerEntry.where(transaction_id: self.id).includes(account: :account_type).where(account_types: {name: ["Bank", "Current Liability"]}).first
  end
  
  def slave_ledger_entries
    LedgerEntry.where(transaction_id: self.id).where.not(id: master_ledger_entry.id)
  end
      
  def balanced?
    credits = total_credits(user.home_asset_type).round(user.home_asset_type.precision) 
    debits = total_debits(user.home_asset_type).round(user.home_asset_type.precision)
    return debits == credits
  end
  
  def asset_types
    asset_types = []
    active_ledger_entries.each do |le|
      asset_type = le.account.asset_type.id
      asset_types.push(asset_type) if !asset_types.include? asset_type
    end
    return asset_types
  end
  
  def date
    return active_ledger_entries.first.date if active_ledger_entries.size > 0
    nil
  end
    
  def total_credits(asset_type)
    total = 0
    active_ledger_entries.each do |le|
      credit = le.credit_in(asset_type)
      total += credit.nil? ? 0 : credit
    end
    total.round(asset_type.precision)
  end
  
  def total_debits(asset_type)
    total = 0
    active_ledger_entries.each do |le|
      debit = le.debit_in(asset_type)
      total += debit.nil? ? 0 : debit
    end
    total.round(asset_type.precision)
  end
  
  def active_ledger_entries
    ledger_entries.select{ |le| le._destroy != true }
  end
    
  private
  
  def repeat_frequency_is_valid
    if !repeat_frequency.blank?
      begin
        IceCube::Schedule.from_yaml(repeat_frequency)
      rescue
        errors.add(:repeat_frequency, "isn't a valid ice_cube schedule")
      end
    end
  end
end
