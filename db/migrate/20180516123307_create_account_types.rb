class CreateAccountTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :account_types do |t|
      t.string :name, :null => false
      t.integer :master_account_type, :null => false

      t.timestamps
    end
  end
end
