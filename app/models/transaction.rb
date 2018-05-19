class Transaction < ApplicationRecord
  belongs_to :user
  
  has_many :transaction_copies, class_name: "Transaction",
                            foreign_key: "prototype_transaction_id"
  belongs_to :prototype_transaction, class_name: "Transaction", optional: true

  has_many :ledger_entries, dependent: :destroy, inverse_of: :parent_transaction
  accepts_nested_attributes_for :ledger_entries, allow_destroy: true
  
  nilify_blanks :only => [:repeat_frequency]

  validate :repeat_frequency_is_valid
  
  before_save :verify_balanced
  before_destroy :verify_not_reconciled

  after_save :update_reserved_amount, :repeat_frequency?
  
  def verify_balanced
    if !balanced?
      errors.add(:base, "credit and debits are out of balance")
      throw :abort
    end
  end
  
  def verify_not_reconciled
    ledger_entries.each do |le|
      if le.reconciled?
        errors.add(:base, "can't delete a transaction with reconciled entries")
        throw :abort
      end
    end
  end

  def update_reserved_amount
    self.user.update_reserved_amount
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
          sch.start_time = next_date + 1.day
          self.repeat_frequency = sch.to_yaml
          self.save

          transaction = self.dup
          transaction.repeat_frequency = nil
          transaction.prototype_transaction_id = self.id
          transaction.save
        
          self.ledger_entries.each do |ledger_entry|
            le = ledger_entry.dup
            le.transaction_id = transaction.id
            le.account_reconciliation_id = nil
            le.date = next_date
            le.save
          end
                
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
    ledger_entries.each do |le|
      asset_type = le.account.asset_type.id
      asset_types.push(asset_type) if !asset_types.include? asset_type
    end
    return asset_types
  end
  
  def date
    return ledger_entries.first.date if ledger_entries.size > 0
    nil
  end
    
  def total_credits(asset_type)
    total = 0
    ledger_entries.each do |le|
      credit = le.credit_in(asset_type)
      total += credit.nil? ? 0 : credit
    end
    total.round(asset_type.precision)
  end
  
  def total_debits(asset_type)
    total = 0
    ledger_entries.each do |le|
      debit = le.debit_in(asset_type)
      total += debit.nil? ? 0 : debit
    end
    total.round(asset_type.precision)
  end
  
  def cleanup_ledger_entries
    t = self.dup
    t.save
    
    ledger_entries.each do |le|
      found = false
      t.ledger_entries.each do |new_le|
        if new_le.account.id == le.account.id
          new_le.credit += le.credit
          new_le.debit += le.debit
          new_le.save
          found = true
        end
      end
      
      if !found
        le.dup
        le.transaction_id = t.id
        le.save
      end
    end
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
