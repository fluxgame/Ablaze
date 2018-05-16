class CreateAccountOwnerships < ActiveRecord::Migration[5.1]
  def change
    create_table :account_ownerships do |t|

      t.timestamps
    end
  end
end
