class AddCurrencyAndPrecisionToAssetTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :asset_types, :currency_symbol, :string
    add_column :asset_types, :precision, :integer
  end
end
