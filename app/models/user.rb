class User < ApplicationRecord
  acts_as_token_authenticatable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :accounts
  has_many :transactions
  has_many :budget_goals
  has_many :report_data
  
  belongs_to :home_asset_type, class_name: 'AssetType'

  def report_data
    last_data_archive = ReportDatum.order(date: :asc).last
    
    if last_data_archive.nil?
      date = Date.parse('2018-01-01')
    else
      date = last_data_archive.date + 1.day
    end
    
    while date < Date.today
      puts "generate data for " + date.to_s
      am = self.aggregate_amounts(date)
      
      rd = ReportDatum.create! user_id: self.id, date: date, 
          average_rate_of_return: am[:average_rate_of_return], 
          annual_savings: am[:savings],
          net_worth: am[:net_worth],
          annual_post_fi_spending: am[:post_fi_expenses]      
      date += 1.day
    end
    
    ReportDatum.where(user_id: self.id)
  end

  def mobile_expense_accounts
    Rails.cache.fetch("#{cache_key}/mobile_expense_accounts", expires_in: 15.minutes) {
      Account.left_joins(:ledger_entries).group(:id).order('count(ledger_entries.id) desc').where(user_id: self.id, mobile: true).joins(:account_type).where(account_types: {master_account_type: :expense})
    }
  end
  
  def expense_accounts
    Rails.cache.fetch("#{cache_key}/expense_accounts", expires_in: 15.minutes) {
      Account.where(user_id: self.id).joins(:account_type).where(account_types: {master_account_type: :expense})
    }
  end    
  
  def mobile_spending_accounts
    Rails.cache.fetch("#{cache_key}/mobile_spending_accounts", expires_in: 15.minutes) {
      Account.left_joins(:ledger_entries).group(:id).order('count(ledger_entries.id) desc').where(user_id: self.id, mobile: true).joins(:account_type).where(account_types: {master_account_type: [:asset, :liability]})
    }
  end
  
  def mobile_budget_goals
    Rails.cache.fetch("#{cache_key}/mobile_budget_goals", expires_in: 15.minutes) {
      BudgetGoal.select{ |bg| bg.remaining_amount > 0 }
    }
  end
  
  def amount_budgeted
    Rails.cache.fetch("#{cache_key}/amount_budgeted", expires_in: 15.minutes) {
      amount_budgeted = 0
      self.budget_goals.each do |goal|
        amount_budgeted += goal.remaining_amount
      end
      return amount_budgeted
    }
  end
    
  def update_reserved_amount
    scheduled_transactions = Transaction.where(user_id: self.id).where.not(repeat_frequency: nil)
    
    self.min_balance_date = Date.today - 1
    self.reserved_amount = running_total = 0
    for i in 1..365
      scheduled_transactions.each do |st|
        if st.schedule.occurs_on?(Date.today + i.day)
          st.ledger_entries.each do |le|
            if le.account.spending_account?
              running_total += (le.credit.nil? ? 0 : le.credit) - (le.debit.nil? ? 0 : le.debit)
            end
          end
        end
      end

      if running_total > self.reserved_amount
        self.reserved_amount = running_total
        self.min_balance_date = Date.today + i.day
      end
    end
    
    self.save
  end
  
  def spendable_at_start_of_today
    ats = self.aggregate_amounts[:current_spending_balance]
    ats += self.spending_today
  end
  
  def available_to_spend  
    self.update_reserved_amount if self.reserved_amount.nil?
    
    ats = self.spendable_at_start_of_today
    ats -= self.amount_budgeted
    ats -= self.reserved_amount
  end
  
  def available_to_spend_today
    atst = self.available_to_spend
    atst /= (self.min_balance_date - Date.today + 1)
    atst -= self.spending_today
  end    

  def spending_today
    Rails.cache.fetch("#{cache_key}/spending_today", expires_in: 1.minute) {
      spending = 0
      LedgerEntry.includes(:parent_transaction).where(transactions: {prototype_transaction_id: nil}, date: Date.today).each do |le|
        amount = le.amount_in(self.home_asset_type)
        spending -= amount if le.account.spending_account?
        spending += amount if le.account.account_type.master_account_type == :income
        spending -= amount if !le.budget_goal_id.nil?
      end
      return spending
    }
  end
                              
  def withdrawal_rate 
    0.04
  end
  
  def fi_target(annual_spending = self.aggregate_amounts[:post_fi_expenses])
    annual_spending / self.withdrawal_rate
  end
  
  def years_to_fi(annual_spending = self.aggregate_amounts[:post_fi_expenses],
    net_worth = self.aggregate_amounts[:net_worth],
    annual_savings = self.aggregate_amounts[:savings],
    rate_of_return = self.aggregate_amounts[:average_rate_of_return])
    
    begin
      Exonio.nper(rate_of_return, annual_savings * -1, net_worth * -1, self.fi_target(annual_spending))
    rescue
      nil
    end
  end
  
  def first_transaction_date 
    first_transaction = LedgerEntry.includes(:account).where(:accounts =>{:user_id => self.id}).where.not(date: nil).order(date: :asc).first
    return first_transaction.date if first_transaction.present?
  end
    
  def fi_date(annual_spending = self.aggregate_amounts[:post_fi_expenses],
    net_worth = self.aggregate_amounts[:net_worth],
    annual_savings = self.aggregate_amounts[:savings],
    rate_of_return = self.aggregate_amounts[:average_rate_of_return])
    
    ytfi = self.years_to_fi(annual_spending, net_worth, annual_savings, rate_of_return)
    return nil if ytfi.nil?
    date = Date.today
    date += ytfi.floor.years
    ytfi = (ytfi - ytfi.floor) * 365    
    date += ytfi.floor.days    
    return date
  end
    
  def recent_transactions
    Rails.cache.fetch("#{cache_key}/recent_transactions", expires_in: 15.minutes) {
      Transaction.left_outer_joins(:ledger_entries).where.not(ledger_entries: {id: nil}).order('ledger_entries.date desc')
        .where("not exists (select 1 from ledger_entries le inner join accounts a on a.id = le.account_id where (le.account_reconciliation_id is not null or le.date is null or a.mobile <> 't' or a.user_id <> ?) and le.transaction_id = transactions.id)", self.id).uniq
    }
  end  
    
  def aggregate_amounts(on_date = Date.today)
    Rails.cache.fetch("#{cache_key}/aggregate_amounts/"+on_date.to_s, expires_in: 15.minutes) {
      am = {
        post_fi_expenses: 0.0,
        lean_fi_expenses: 0.0,
        post_fi_expenses_pre_tax: 0.0,
        lean_fi_expenses_pre_tax: 0.0,
        expenses: 0.0, 
        savings: 0.0, 
        active_income: 0.0, 
        average_rate_of_return: 0.0,
        assets: 0.0,
        liabilities: 0.0,
        net_worth: 0.0,
        current_spending_balance: 0
      }
      
      self.accounts.each do |account|
        puts "\n\nAccount: " + account.name
        puts "Post FI Expenses: " + am[:post_fi_expenses].to_s
        years_of_transactions = account.years_of_transactions(on_date)
        if years_of_transactions > 0
          account_type = account.account_type.master_account_type.to_sym

          if account_type == :expense
            avg_annual_spend = account.average_monthly_spending(self.home_asset_type, on_date) * 12
            puts "Average Annual Spend: " + avg_annual_spend.to_s
            am[:savings] -= avg_annual_spend
            am[:expenses] += avg_annual_spend
            am[:post_fi_expenses_pre_tax] += [avg_annual_spend, account.fi_budget * 12].max if account.post_fi_expense?
            am[:lean_fi_expenses_pre_tax] += (account.fi_budget * 12)
          elsif account.name == "Active Income"
            avg_annual_spend = account.average_monthly_spending(self.home_asset_type, on_date) * 12
            puts "Average Annual Spend: " + avg_annual_spend.to_s
            am[:savings] -= avg_annual_spend
            am[:active_income] -= avg_annual_spend
          elsif [:asset, :liability].include?(account_type)
            account_balance = account.balance_as_of(on_date, self.home_asset_type)
            if account_balance.present?
              am[:average_rate_of_return] += (account.expected_annual_return * account_balance)
              am[:assets] += account_balance if account_type == :asset
              am[:liabilities] += account_balance if account_type == :liability
              am[:current_spending_balance] += account_balance if account.spending_account?
            end
          end
        end
      end
           
      am[:net_worth] = am[:assets] + am[:liabilities]
      am[:average_rate_of_return] /= am[:net_worth]
      am[:post_fi_expenses] = adjust_for_taxes(am[:post_fi_expenses_pre_tax])
      am[:lean_fi_expenses] = adjust_for_taxes(am[:lean_fi_expenses_pre_tax])
      am
    }
  end
  
  def adjust_for_taxes(annual_spending)
    federal_tax_rate = 0.1
    state_tax_rate = 0.051
  
    federal_deduction = 24000
    state_deduction = 8800
    
    (annual_spending - federal_deduction * federal_tax_rate - state_deduction * state_tax_rate) / (1 - federal_tax_rate - state_tax_rate)
  end

  def days_of_work(account)
    return 0 if !account.post_fi_expense?
    
    days_to_lean_fi = self.years_to_fi(self.aggregate_amounts[:lean_fi_expenses]) * 365
    days_to_full_fi = self.years_to_fi(self.aggregate_amounts[:post_fi_expenses]) * 365
    days_per_dollar = (days_to_full_fi - days_to_lean_fi) / (self.aggregate_amounts[:post_fi_expenses_pre_tax] - self.aggregate_amounts[:lean_fi_expenses_pre_tax])
    return (12 * days_per_dollar * ([0, account.average_monthly_spending(self.home_asset_type) - account.fi_budget].max)).round(0)
  end
end