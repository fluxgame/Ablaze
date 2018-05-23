require 'date'

desc "This task is called by the Heroku scheduler add-on"

task :create_scheduled_transactions => :environment do
  Transaction.where.not(repeat_frequency: nil).each do |st| st.create_next_occurence end
  User.all.each do |u| u.update_reserved_amount end
end

task :update_asset_valuations => :environment do
  AssetType.where(fetch_prices: true).each do |at| at.fetch_valuations end
end

task :update_available_to_spend => :environment do
  User.all.each do |u| u.update_available_to_spend end
end