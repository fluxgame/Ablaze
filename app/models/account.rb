class Account < ApplicationRecord
  belongs_to :asset_type
  belongs_to :account_type

  belongs_to :user, touch: true
  has_many :account_reconciliations
  has_many :account_balances
  has_many :ledger_entries
  has_many :budget_goals
  
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
        balance += LedgerEntry.where(account_id: self.id, date: date).sum('coalesce(debit,0) - coalesce(credit,0)')

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
    cleared_amounts = LedgerEntry.where(account_id: self.id, cleared: true, account_reconciliation_id: nil).sum('coalesce(debit,0) - coalesce(credit,0)')
    self.asset_type.exchange(reconciled_balance + cleared_amounts, in_asset_type)
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
  
  def years_of_transactions(on_date = Date.today)
    first_transaction = LedgerEntry.where(account_id: self.id).where.not(date: nil).order(date: :asc).first
    if first_transaction.nil?
      return 0
    else
      return (on_date - first_transaction.date) / 365.25
    end
  end
  
  def average_weekly_spending(on_date = Date.today, in_asset_type = self.asset_type)
    if [:expense, :income].include? self.account_type.master_account_type.to_sym
#      on_date = on_date.beginning_of_week(:sunday) - 1
      yot = self.years_of_transactions(on_date)
      return 0 if yot <= 0
      return (self.balance_as_of(on_date, in_asset_type) / yot / (365.25 / 7)).round(in_asset_type.precision)
    end
    
    nil
  end
  
  def weekly_budget(in_asset_type = self.asset_type)
    budget = self.asset_type.exchange(self.fi_budget, in_asset_type)
    budget = 0 if budget.nil?
    budget
  end
  
  def allowed_spending(on_date = Date.today, in_asset_type = self.asset_type)
    (self.weekly_budget(in_asset_type) * self.years_of_transactions(on_date) * (365.25 / 7)).round(in_asset_type.precision)
  end

  def available_to_budget(on_date = Date.today, in_asset_type = self.asset_type)
    weekly_budget = self.weekly_budget(in_asset_type)

    return nil if weekly_budget == 0

    allowed_spending(on_date, in_asset_type) - self.balance_as_of(on_date) - self.budgeted_amount - weekly_budget
    
=begin
    budget = self.asset_type.exchange(self.fi_budget, in_asset_type)
    
    return nil if budget.nil? || budget == 0  
    
    last_saturday = on_date.beginning_of_week(:sunday) - 1
    
    atb = budget * self.years_of_transactions(last_saturday) * (365.25 / 7)
    atb -= self.balance_as_of(last_saturday)
    atb -= budget + self.budgeted_amount + self.budgeted_spending_this_week(in_asset_type, on_date)

    atb.round(self.asset_type.precision)
=end
  end

  def available_to_spend(on_date = Date.today, in_asset_type = self.asset_type)
    weekly_budget = self.weekly_budget(in_asset_type)

    return nil if weekly_budget == 0
    
    ats = available_to_budget(on_date, in_asset_type) + weekly_budget

=begin
    if ats < 0
      spent = self.balance_as_of(on_date, in_asset_type) + self.budgeted_amount
      average_spend = (spent / self.years_of_transactions(on_date) / (365.25 / 7)).round(in_asset_type.precision)
      if average_spend > weekly_budget
        ats = (weekly_budget - (average_spend - weekly_budget) ** 1.3).round(in_asset_type.precision) 
      else
        ats = weekly_budget
      end
=end
    
    ats = weekly_budget if ats > weekly_budget && self.budgeted_amount != 0
    
    ats
=begin
    ats = self.this_weeks_budget(in_asset_type, on_date) - unplanned_spending_this_week(in_asset_type, on_date)
    if self.budget_goals.count == 0
      atb = available_to_budget(in_asset_type, on_date)
      ats += atb if atb.present? && atb > 0
    end
    ats
=end    
  end
  

=begin
  def unplanned_spending_this_week(in_asset_type = self.asset_type, on_date = Date.today)
    last_sunday = on_date.beginning_of_week(:sunday)
    next_sunday = on_date.next_occurring(:sunday)
    LedgerEntry.joins(:parent_transaction).where(transactions: {prototype_transaction_id: nil}, budget_goal_id: nil, account_id: self.id).where('date >= ? and date < ?',last_sunday, next_sunday).sum(:debit)
  end
  
  def budgeted_spending_this_week(in_asset_type = self.asset_type, on_date = Date.today)
    last_sunday = on_date.beginning_of_week(:sunday)
    next_sunday = on_date.next_occurring(:sunday)
    LedgerEntry.where.not(budget_goal_id: nil).where(account_id: self.id).where('date >= ? and date < ?',last_sunday, next_sunday).sum(:debit)
  end  
  
  def this_weeks_budget(in_asset_type = self.asset_type, on_date = Date.today)
    twb = self.asset_type.exchange(self.fi_budget, in_asset_type)
    
    return 0 if twb.nil? || twb == 0
    
    average_spend = average_weekly_spending(in_asset_type, on_date)
    
    twb -= (average_spend - twb) ** 1.3 if average_spend > twb
    
    twb.round(self.asset_type.precision)
  end
=end    
  
  def budgeted_amount
    amount = 0
    budget_goals.each do |goal|
      amount += goal.remaining_amount
    end
    amount
  end
  
  def post_fi_expense?
    !['Interest Expense','Income Tax','Payroll Taxes','Health Insurance'].include?(name) && self.account_type.master_account_type.to_sym == :expense
  end
  
  def lean_fi_expense?
    ['Food','Transportation','Housing','Health','Pets'].include?(name)
  end
  
  def expected_annual_return
    self[:expected_annual_return].nil? ? 0 : self[:expected_annual_return]
  end
  
  def spending_account?
    self.account_type.name == "Bank" || self.account_type.name == "Current Liability"
  end
  
  def asset_or_liability?
    [:asset, :liability].include?(self.account_type.master_account_type.to_sym)
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
