class Account < ApplicationRecord
  belongs_to :asset_type
  belongs_to :account_type

  belongs_to :user, touch: true
  has_many :account_reconciliations
  has_many :account_balances
  has_many :ledger_entries
  
  attr_reader :balance
  
  def Account.accounts_of_type(master_account_type, user)
      Account.where(user_id: user.id)
        .includes(:account_type).where(:account_types => {master_account_type: master_account_type})      
  end

  def current_balance(in_asset_type = self.asset_type)
    self.balance_as_of(Date.today, in_asset_type)
  end
  
  def balance_as_of(date, in_asset_type = self.asset_type)
    raise ArgumentError.new("date is a " + date.class.name) if (!date.is_a?(Date))
    raise ArgumentError.new("Can't calculate a future balance.") if (date > Date.today)
      
    stored_balance = AccountBalance.where(date: date, account_id: self.id).first

    if stored_balance.nil?
      previous_ledger_entry = LedgerEntry.where(account_id: self.id).where('date <= ?', date).order(date: :desc).first
      return 0 if previous_ledger_entry.nil?

      if previous_ledger_entry.date == date
        balance = self.balance_as_of(date - 1.day)
        balance -= LedgerEntry.where(account_id: self.id, date: date).sum(:credit)
        balance += LedgerEntry.where(account_id: self.id, date: date).sum(:debit)

        stored_balance = self.account_balances.create! account_id: self.id, date: date, balance: balance
        LedgerEntry.where(account_id: self.id, date: date).update_all(account_balance_id: stored_balance.id)
      else 
        balance = self.balance_as_of(previous_ledger_entry.date)
      end
    else
      balance = stored_balance.balance
    end
      
    self.asset_type.exchange(balance, in_asset_type, date)
  end
  
  def change_in_balance(start_date, end_date, in_asset_type)
    balance_as_of(end_date, in_asset_type) - balance_as_of(start_date, in_asset_type)
  end
  
  def cleared_balance(in_asset_type = self.asset_type)
    credits = LedgerEntry.where(account_id: self.id, cleared: true, account_reconciliation_id: nil).sum(:credit)
    debits = LedgerEntry.where(account_id: self.id, cleared: true, account_reconciliation_id: nil).sum(:debit)

    self.asset_type.exchange(reconciled_balance + debits - credits, in_asset_type)
  end
  
  def latest_reconciliation
    AccountReconciliation.where(account_id: self.id).order(date: :desc).limit(1).first
  end
  
  def reconciled_balance(in_asset_type = self.asset_type)
    if !latest_reconciliation.nil?
      self.asset_type.exchange(latest_reconciliation.balance, in_asset_type, latest_reconciliation.date)
    else
      0
    end
  end
  
  def years_of_transactions
    first_transaction = LedgerEntry.where(account_id: self.id).order(date: :asc).first
    if first_transaction.nil?
      return 0
    else
      return (Date.today - first_transaction.date) / 365
    end
  end
  
  def average_monthly_spending(in_asset_type = self.asset_type)
      yot = self.years_of_transactions
      if (yot > 0)
        return self.current_balance(in_asset_type) / yot / 12
      else
        return 0
      end
  end
  
  def last_months_spending(in_asset_type = self.asset_type)
    self.change_in_balance(Date.today - 1.month, Date.today, in_asset_type)
  end
  
  def post_fi_expense?
    !['Interest Expense','MA Taxes','Federal Taxes','Payroll Taxes'].include?(name)    
#    ['Housing','Transportation','Pets','Health','Discretionary - Joint','Discretionary - Dave','Discretionary - Jess'].include?(name)
  end
  
  def expected_annual_return
    self[:expected_annual_return].nil? ? 0 : self[:expected_annual_return]
  end
  
  def spending_account?
    self.account_type.name == "Bank" || self.account_type.name == "Current Liability"
  end
      
  def import_ofx
    clearing_account = Account.where(name: 'Clearing').first
    
    OFX("/Users/flux/Downloads/MC_840_040118_050618.QFX").account.transactions.each do |t|
      matching_entries = LedgerEntry.where(debit: t.amount).or(LedgerEntry.where(credit: t.amount * -1)).where(account_id: self.id).where('date >= ?', t.posted_at.to_date - 1.day).where('date <= ?', t.posted_at.to_date + 1.day)
      
      if matching_entries.count == 1
        matching_entries.first.cleared = true
        matching_entries.first.save
      elsif matching_entries.count == 0 && t.amount != 0
        trans = Transaction.create!(description: t.name, user_id: self.user.id)
        if (t.amount < 0)
          trans.ledger_entries.create!(cleared: true, date: t.posted_at.to_date, credit: t.amount * -1, account_id: self.id)
          trans.ledger_entries.create!(cleared: false, date: t.posted_at.to_date, debit: t.amount * -1, account_id: clearing_account.id)
        else
          trans.ledger_entries.create!(cleared: true, date: t.posted_at.to_date, debit: t.amount, account_id: self.id)
          trans.ledger_entries.create!(cleared: false, date: t.posted_at.to_date, credit: t.amount, account_id: clearing_account.id)
        end
      end
    end
    
    self.do_update_balances = true
    self.update_balances
  end
end
