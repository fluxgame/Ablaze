class CreateAssetTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :asset_types do |t|
      t.string :name, :null => false
      t.string :abbreviation, :null => false
      t.boolean :fetch_prices, :null => false, :default => false
      t.string :currency_symbol
      t.integer :precision, :null => false, :default => 2

      t.timestamps
    end

    # AssetType.create! do |at|
    #     at.name = 'United States Dollars'
    #     at.abbreviation = 'USD'
    #     at.fetch_prices = false
    #     at.currency_symbol = '$'
    #     at.precision = 2
    # end

  end
end
