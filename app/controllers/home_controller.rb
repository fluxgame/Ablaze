class HomeController < ApplicationController
  def reports
    @fi_date_data = [{name: "Lean FI Date", data: []},{name: "Full FI Date", data: []}]
    
    current_user.report_data.each do |rd|
      lean_fi_date = current_user.fi_date(current_user.aggregate_amounts[:lean_fi_expenses], rd.net_worth, rd.annual_savings, rd.average_rate_of_return)
      full_fi_date = current_user.fi_date(rd.annual_post_fi_spending, rd.net_worth, rd.annual_savings, rd.average_rate_of_return)
      
      if full_fi_date.present? && lean_fi_date.present?
        @fi_date_data[0][:data].push([rd.date, lean_fi_date.to_time.to_i / (60 * 60 * 24)])
        @fi_date_data[1][:data].push([rd.date, full_fi_date.to_time.to_i / (60 * 60 * 24)])
      end
    end
      
  end
  
  def forecasting
    scheduled_amounts = []
    Transaction.where(user_id: current_user.id).where.not(repeat_frequency: nil).each do |st|
      amount = 0
      st.ledger_entries.each do |le|
        if le.account.spending_account?
            amount += le.amount_in(current_user.home_asset_type)
        end
      end
      
      scheduled_amounts.push({amount: amount, schedule: st.schedule})
    end
    
    @days = []
    running_total = current_user.spendable_at_start_of_today - current_user.amount_budgeted
    for i in 0..364
      date = Date.today + (i+1).days
      amount = 0
      scheduled_amounts.each do |sa|
        if sa[:schedule].occurs_on?(date)
          amount += sa[:amount]
        end
      end
      
      if amount != 0
        running_total += amount
        @days.push({date: date, amount: amount, running_total: running_total})
      end
    end
    
    @days.sort! { |a, z| a[:running_total] <=> z[:running_total] }
    
    @minimums = [@days[0]]
    @days.shift
    
    @days.each do |day|
      @minimums.push(day) if day[:date] > @minimums.last[:date]
    end
     
    i = 1
    @minimums.each do |min|
      if @minimums[i].present?
        min[:days_till_next] = (@minimums[i][:date] - min[:date]).to_i
        min[:available_to_spend] = (min[:running_total] / min[:days_till_next]).to_f
        i += 1
      end
    end
    
    @minimums.pop
    
    @minimums.sort! { |a, z| a[:available_to_spend] <=> z[:available_to_spend] }
    @available_to_budget = (@minimums[0][:available_to_spend] - 50) * @minimums[0][:days_till_next]
  end
end
