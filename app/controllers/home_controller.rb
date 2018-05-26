class HomeController < ApplicationController
  def net_worth
    puts "Net Worth Report"
    @net_worth_report = []
    
    for i in 0..364
      puts i
      @net_worth_report.push({date: Date.today - i.day, net_worth: 0})
    end
    
    puts @net_worth_report
    
    current_user.accounts.each do |account|
      if [:asset, :liability].include? account.account_type.master_account_type.to_sym
        for i in 0..364
          @net_worth_report[i][:net_worth] += account.balance_as_of(Date.today - i.day, current_user.home_asset_type)
        end
      end
    end
    
    puts @net_worth_report
  end
end
