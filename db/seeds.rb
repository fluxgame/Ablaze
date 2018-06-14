# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


require 'csv'    

LedgerEntry.delete_all
Transaction.delete_all
AccountReconciliation.delete_all
Account.delete_all
BudgetedAmount.delete_all
BudgetGoal.delete_all
User.delete_all
AssetType.delete_all
AccountType.delete_all

CSV.foreach("db/seed_asset_types.csv", :headers => true, :return_headers => false) do |row|
#  id,name,abbreviation,created_at,updated_at,fetch_prices,currency_symbol,precision
  AssetType.new do |t|
    t.id = row[0]
    t.name = row[1]
    t.abbreviation = row[2]
    t.fetch_prices = row[5]
    t.currency_symbol = row[6]
    t.precision = row[7]
    t.save
  end
end

ActiveRecord::Base.connection.execute("SELECT setval('asset_types_id_seq', (SELECT max(id) FROM asset_types));")

CSV.foreach("db/seed_account_types.csv", :headers => true, :return_headers => false) do |row|
#  id,name,master_account_type,created_at,updated_at
  AccountType.new do |t|
    t.id = row[0]
    t.name = row[1]
    t.master_account_type = AccountType.master_account_types.keys[row[2].to_i]
    t.save
  end
end

ActiveRecord::Base.connection.execute("SELECT setval('account_types_id_seq', (SELECT max(id) FROM account_types));")

user = User.create!(email: "fluxgame@gmail.com", password: "123456", authentication_token: "_sMbFzbPr_b7dF7V9sCk", home_asset_type_id: AssetType.where(abbreviation: 'USD').first.id)

CSV.foreach("db/seed_accounts.csv", :headers => true, :return_headers => false) do |row|
#  id,name,expected_annual_return,asset_type_id,account_type_id,created_at,updated_at,days_to_forecast,user_id,mobile
  Account.new do |t|
    t.id = row[0]
    t.name = row[1]
    t.expected_annual_return = row[2]
    t.asset_type_id = row[3]
    t.account_type_id = row[4]
    t.user = user
    t.mobile = row[9]
    t.save
  end
end

ActiveRecord::Base.connection.execute("SELECT setval('accounts_id_seq', (SELECT max(id) FROM accounts));")

CSV.foreach("db/seed_transactions.csv", :headers => true, :return_headers => false) do |row|
#  id,repeat_frequency,user_id,prototype_transaction_id,created_at,updated_at,description
  Transaction.new do |t|
    t.id = row[0]
    t.repeat_frequency = row[1]
    t.user = user
    t.prototype_transaction_id = row[3]
    t.description = row[6]
    t.save
  end
end

ActiveRecord::Base.connection.execute("SELECT setval('transactions_id_seq', (SELECT max(id) FROM transactions));")

CSV.foreach("db/seed_account_reconciliations.csv", :headers => true, :return_headers => false) do |row|
#  id,account_id,balance,date
  AccountReconciliation.new do |t|
    t.id = row[0]
    t.account_id = row[1]
    t.balance = row[2]
    t.date = row[3]
    t.save
  end
end

ActiveRecord::Base.connection.execute("SELECT setval('account_reconciliations_id_seq', (SELECT max(id) FROM account_reconciliations));")

CSV.foreach("db/seed_budget_goals.csv", :headers => true, :return_headers => false) do |row|
#id,budgeted_amount,name,user_id,created_at,updated_at
  bg = BudgetGoal.new do |t|
    t.id = row[0]
    t.name = row[2]
    t.user = user
    t.save
  end
  
  bg.budgeted_amounts.create! amount: row[1], date: Date.today
end

ActiveRecord::Base.connection.execute("SELECT setval('budget_goals_id_seq', (SELECT max(id) FROM budget_goals));")

CSV.foreach("db/seed_ledger_entries.csv", :headers => true, :return_headers => false) do |row|
#  id,cleared,debit,credit,account_id,budget_goal_id,transaction_id,created_at,updated_at,date,account_reconciliation_id,account_reconciliations_id,account_balance_id
  LedgerEntry.new do |t|
    t.id = row[0]
    t.cleared = row[1]
    t.debit = row[2]
    t.credit = row[3]
    t.account_id = row[4]
    t.budget_goal_id = row[5]
    t.transaction_id = row[6]
    t.date = row[9]
    t.account_balance_id = row[11]
    t.save
    t.account_reconciliation_id = row[10]
    t.save
  end
end

ActiveRecord::Base.connection.execute("SELECT setval('ledger_entries_id_seq', (SELECT max(id) FROM ledger_entries));")

UpdateAssetValuations.perform_now
CreateScheduledTransactions.perform_now
Account.all.each do |a|
  a.balance_as_of(Date.today)
end