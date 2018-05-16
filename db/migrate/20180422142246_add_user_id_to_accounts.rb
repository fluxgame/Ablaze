class AddUserIdToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_reference :accounts, :user, index: true
    
    ActiveRecord::Base.connection.execute("update accounts set user_id = 1")
    
    drop_table :account_ownerships
  end
end
