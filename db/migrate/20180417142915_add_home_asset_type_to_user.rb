class AddHomeAssetTypeToUser < ActiveRecord::Migration[5.1]
  def self.up
    add_column :users, :home_asset_type_id, :integer, index: true
   end

   def self.down
     remove_column :users, :home_asset_type_id
   end    
end
