class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :accounts do |t|
      t.string :name, :null => false
      t.float :expected_annual_return
      t.references :asset_type, foreign_key: true, :null => false
      t.references :account_type, foreign_key: true, :null => false

      t.timestamps
    end
  end
end
