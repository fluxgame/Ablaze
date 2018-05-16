# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


require 'csv'    

LedgerEntry.all.each { |a| a.destroy } 
Transaction.all.each { |a| a.destroy } 
Account.all.each { |a| a.destroy } 
AssetType.all.each { |a| a.destroy } 
AccountType.all.each { |a| a.destroy } 

asset_type_list = [
  [ "USD", "United States Dollars" ],
  [ "VTI", "Vanguard Total Stock Market ETF" ],
  [ "VTSAX", "Vanguard Total Stock Market Index Fund Admiral Shares" ],
  [ "HOUSE", "45 Havelock Rd"]
]

asset_type_list.each do |abbreviation, name|
  AssetType.create( name: name, abbreviation: abbreviation )
end

#   enum master_account_type: [:asset, :liability, :equity, :income, :expense]
account_type_list = [
  [ "Income", 4 ],
  [ "Expense", 3 ],
  [ "Equity", 2 ],
  [ "Long-Term Liability", 1 ],
  [ "Current Liability", 1 ],
  [ "Deferred Asset", 0 ],
  [ "Fixed Asset", 0 ],
  [ "Current Asset", 0 ],
  [ "Bank", 0 ]
]

account_type_list.each do |name, master_account_type|
  AccountType.create( name: name, master_account_type: master_account_type )
end

user = User.where(email: "fluxgame@gmail.com").first

CSV.foreach("db/seed_accounts.csv", :headers => true, :return_headers => false) do |row|
  puts row
  account_type = AccountType.where(name: row[3]).first.id
  asset_type = AssetType.where(abbreviation: row[2]).first.id
  account = Account.create!(name: row[0], expected_annual_return: row[1], account_type_id: account_type, asset_type_id: asset_type)
  account.account_ownerships.create(user: user)
end

CSV.foreach("db/seed_transactions.csv", :headers => true, :return_headers => false) do |row|
  puts row
  debit_account = Account.where(name: row[2]).first.id
  credit_account = Account.where(name: row[3]).first.id
  transaction = Transaction.create!(description: row[1], user_id: 1)
  transaction.ledger_entries.create!(date: row[0], account_id: debit_account, debit: row[4], cleared: false)
  transaction.ledger_entries.create!(date: row[0], account_id: credit_account, credit: row[4], cleared: false)
end
