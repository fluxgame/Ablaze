class AddFetchPricesFlagToAssetType < ActiveRecord::Migration[5.1]
  def change
    add_column :asset_types, :fetch_prices, :boolean, :null => false, :default => false
  end
end
