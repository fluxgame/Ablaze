class ChangeAccountBalanceDateFromDatetimeToDate < ActiveRecord::Migration[5.1]
  def change
    change_column :account_balances, :date, :date
  end
end
