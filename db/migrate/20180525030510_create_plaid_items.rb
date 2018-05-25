class CreatePlaidItems < ActiveRecord::Migration[5.2]
  def change
    create_table :plaid_items do |t|
	    t.references :user, foreign_key: true, :null => false
      t.integer :item_id, :null => false
      t.string :access_token, :null => false
      
      t.timestamps
    end
  end
end
