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
end
