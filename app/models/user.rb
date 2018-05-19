class User < ApplicationRecord
  acts_as_token_authenticatable

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :accounts
  has_many :setting, :through => :user_settings
  has_many :ledger_entries
  
  belongs_to :home_asset_type, class_name: 'AssetType'
  has_many :budget_goals

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
      BudgetGoal.where.not(name: ["Buffer", "Reserved"]).select{ |bg| bg.remaining_amount > 0 }
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
    
    budgeted_amount = running_total = 0
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
      budgeted_amount = running_total if running_total > budgeted_amount
    end
    
    rg = self.reserved_goal
    BudgetedAmount.where(budget_goal_id: rg.id).delete_all
    rg.budgeted_amounts.create! amount: budgeted_amount, date: Date.today
  end
  
  def reserved_goal
    reserved_goal_name = "Reserved"
    reserved_goal = BudgetGoal.where(user_id: self.id, name: reserved_goal_name).first
    
    if reserved_goal.nil?
      reserved_goal = BudgetGoal.new
      reserved_goal.name = reserved_goal_name
      reserved_goal.user_id = self.id
      reserved_goal.save
    end
    
    return reserved_goal
  end
  
  def available_to_spend 
    self.aggregate_amounts[:current_spending_balance] - self.amount_budgeted
  end
                            
  def withdrawal_rate 
    0.04
  end
  
  def fi_target
    self.aggregate_amounts[:post_fi_expenses] / self.withdrawal_rate
  end
  
  def years_to_fi
    begin
      Exonio.nper(self.aggregate_amounts[:average_rate_of_return], self.aggregate_amounts[:savings] * -1, self.aggregate_amounts[:net_worth] * -1, self.fi_target)
    rescue
      nil
    end
  end
  
  def first_transaction_date 
    first_transaction = LedgerEntry.includes(:account).where(:accounts =>{:user_id => self.id}).where.not(date: nil).order(date: :asc).first
    return first_transaction.date if first_transaction.present?
  end
    
  def fi_date
    return nil if self.years_to_fi.nil?
    ytfi = self.years_to_fi
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
    
  def aggregate_amounts
    Rails.cache.fetch("#{cache_key}/aggregate_amounts", expires_in: 15.minutes) {
      am = {
        post_fi_expenses: 0.0, 
        expenses: 0.0, 
        savings: 0.0, 
        active_income: 0.0, 
        average_rate_of_return: 0.0,
        assets: 0.0,
        liabilities: 0.0,
        net_worth: 0.0,
        current_spending_balance: 0
      }

      first_transaction_date = self.first_transaction_date
      
      if !first_transaction_date.nil?
        self.accounts.each do |account|
          account_type = account.account_type.master_account_type.to_sym
          
          if account_type == :expense || account.name == "Active Income"
            annual_amount = account.change_in_balance(Date.today - 1.year, Date.today, self.home_asset_type)
            am[:savings] -= annual_amount
            if account.name == "Active Income"
              am[:active_income] -= annual_amount 
            else
              am[:expenses] += annual_amount
              am[:post_fi_expenses] += annual_amount if account.post_fi_expense?
            end
          elsif [:asset, :liability].include?(account_type)
            puts account.name
            account_balance = account.current_balance(self.home_asset_type)
            am[:average_rate_of_return] += account.expected_annual_return * (account_balance.nil? ? 0 : account_balance)
            am[:assets] += account_balance if account_type == :asset
            am[:liabilities] += account_balance if account_type == :liability
            am[:current_spending_balance] += account_balance if account.spending_account?
          end
        end
        
        years_of_transactions = (Date.today - first_transaction_date) / 365
        am[:savings] /= years_of_transactions
        am[:expenses] /= years_of_transactions
        am[:post_fi_expenses] /= years_of_transactions
        am[:active_income] /= years_of_transactions
   
        am[:net_worth] = am[:assets] + am[:liabilities]
        am[:average_rate_of_return] /= am[:net_worth]
        
        federal_tax_rate = 0.1
        state_tax_rate = 0.051
    
        federal_deduction = 24000
        state_deduction = 8800
    
        am[:post_fi_expenses] = (am[:post_fi_expenses] - federal_deduction * federal_tax_rate - state_deduction * state_tax_rate) / (1 - federal_tax_rate - state_tax_rate)
#        am[:average_rate_of_return] = 0.07
      end      
            
      am
    }
  end
end