class HomeController < ApplicationController
  def reports
    @fi_date_data = [{name: "Days to Lean FI", data: []},{name: "Days to Full FI", data: []},{name: "Lean FI Date", data: []},{name: "Full FI Date", data: []}]
    
    current_user.report_data.each do |rd|
      full_fi_date = current_user.fi_date(rd.date, rd.annual_post_fi_spending, rd.net_worth, rd.annual_savings, rd.average_rate_of_return)
      
      if full_fi_date.present?
        @fi_date_data[0][:data].push([rd.date, full_fi_date - rd.date])
      end
    end
      
  end
  
  def taxes
    start_date = Date.new(params[:year].present? ? params[:year].to_i : Date.today.year,1,1)
    end_date = start_date + 1.year - 1.day
    
    taxable_ledger_entries = LedgerEntry.includes(:parent_transaction)
        .where(transactions: {user_id: current_user.id}, tax_related: true)
        .where('date >= ? and date <= ?', start_date, end_date)
    
    @taxable_amounts = Hash.new
    @taxable_income = 0
    @dividend_income = 0
    @lt_capital_gain_income = 0
    @deductions = 0
    taxable_ledger_entries.each do |le|
      amount = le.amount_in(current_user.home_asset_type) 
      account_type = le.account.account_type.master_account_type.to_sym

      @taxable_amounts[le.account.name] = 0 if @taxable_amounts[le.account.name].nil?
      @taxable_amounts[le.account.name] -= amount
      
      if :income == account_type
        @taxable_income -= amount
        @dividend_income -= amount if le.account.name == "Dividends"
        @lt_capital_gain_income -= amount if le.account.name == "Long-Term Capital Gains"
      else
        @deductions += amount
      end
    end
    
    if end_date < Date.today
      @year_progress = 1
    else
      @year_progress = Date.today.yday.to_f / end_date.yday.to_f
    end
    
    @projected_taxable = (@taxable_income - @deductions) / @year_progress
    
    @projected_div_cap_gains = @lt_capital_gain_income + @dividend_income / @year_progress
    
    @projected_fed_tax = current_user.calculate_fed_tax(@projected_taxable, @projected_div_cap_gains)
    @projected_state_tax = current_user.calculate_state_tax(@projected_taxable, @projected_div_cap_gains)
    @projected_tax = @projected_fed_tax + @projected_state_tax
    
    @fed_taxes_witheld = Account.where(name: "Federal Tax").first.balance_as_of([end_date, Date.today].min)
    @state_taxes_witheld = Account.where(name: "State Tax").first.balance_as_of([end_date, Date.today].min)
  end
end
