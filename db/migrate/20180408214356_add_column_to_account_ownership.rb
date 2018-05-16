class AddColumnToAccountOwnership < ActiveRecord::Migration[5.1]
  def change
    add_column :account_ownerships, :account_id, :integer
    add_column :account_ownerships, :user_id, :integer
  end
end
