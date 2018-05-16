class AddValuationAssetTypeToAssetValuations < ActiveRecord::Migration[5.1]
  def self.up
    add_column :asset_valuations, :valuation_asset_type_id, :integer, index: true
    change_column :asset_valuations, :valuation_asset_type_id, :integer, index: true, :null => false
    add_foreign_key :asset_valuations, :assets, column: :valuation_asset_type_id
   end

   def self.down
     remove_column :asset_valuations, :valuation_asset_type_id
   end
end
