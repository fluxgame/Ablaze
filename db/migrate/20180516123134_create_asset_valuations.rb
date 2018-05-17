class CreateAssetValuations < ActiveRecord::Migration[5.2]
  def change
    create_table :asset_valuations do |t|
      t.date :date, :null => false
      t.belongs_to :asset_type, index: true, null: false, foreign_key: { to_table: :asset_types}
      t.belongs_to :valuation_asset_type, index: true, null: false, foreign_key: { to_table: :asset_types}
      t.float :amount, :null => false

      t.timestamps
    end
	
	  add_index :asset_valuations, [:asset_type_id, :date], unique: true, name: "asset_type_id_date_index"
  end
end
