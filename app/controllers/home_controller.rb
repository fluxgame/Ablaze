class HomeController < ApplicationController
  def reports
    @fi_date_data = [{name: "Days to Lean FI", data: []},{name: "Days to Full FI", data: []},{name: "Lean FI Date", data: []},{name: "Full FI Date", data: []}]
    
    current_user.report_data.each do |rd|
      lean_fi_date = current_user.fi_date(current_user.aggregate_amounts[:lean_fi_expenses], rd.net_worth, rd.annual_savings, rd.average_rate_of_return)
      full_fi_date = current_user.fi_date(rd.annual_post_fi_spending, rd.net_worth, rd.annual_savings, rd.average_rate_of_return)
      
      if full_fi_date.present? && lean_fi_date.present?
        @fi_date_data[0][:data].push([rd.date, lean_fi_date - rd.date])
        @fi_date_data[1][:data].push([rd.date, full_fi_date - rd.date])
        @fi_date_data[2][:data].push([rd.date, lean_fi_date.to_time.to_i / (60 * 60 * 24) / 365.25 * 12])
        @fi_date_data[3][:data].push([rd.date, full_fi_date.to_time.to_i / (60 * 60 * 24) / 365.25 * 12])
      end
    end
      
  end
  
  def taxes
    start_date = Date.new(params[:year].present? ? params[:year].to_i : Date.today.year,1,1)
    end_date = start_date + 1.year - 1.day
    
    taxable_ledger_entries = LedgerEntry.includes(:parent_transaction)
        .where(transactions: {user_id: current_user.id, prototype_transaction_id: nil}, tax_related: true)
        .where('date >= ? and date <= ?', start_date, end_date)
    
    @taxable_amounts = Hash.new
    taxable_ledger_entries.each do |le|
      @taxable_amounts[le.account.name] = 0 if @taxable_amounts[le.account.name].nil?
      @taxable_amounts[le.account.name] += (le.debit.nil? ? 0 : le.debit) - (le.credit.nil? ? 0 : le.credit)
    end
  end
end
