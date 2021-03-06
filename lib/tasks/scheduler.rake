require 'date'

desc "This task is called by the Heroku scheduler add-on"

task :create_scheduled_transactions => :environment do
  Transaction.where.not(repeat_frequency: nil).each do |st| st.create_next_occurence end
end

task :update_asset_valuations => :environment do
  AssetType.where(fetch_prices: true).each do |at| at.fetch_valuations end
  ActiveRecord::Base.connection.exec_query("delete from asset_valuations where id not in (select distinct av.id from asset_valuations av inner join accounts a on a.asset_type_id = av.asset_type_id inner join ledger_entries le on le.account_id = a.id and le.date = av.date) and date < current_date - 120;")
end  