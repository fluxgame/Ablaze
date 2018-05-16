class CreateAssetValuations < ActiveRecord::Migration[5.1]
  def change
    create_table :asset_valuations do |t|
      t.datetime :date, :null => false
      t.references :asset_type, foreign_key: true, :null => false
      t.float :amount, :null => false

      t.timestamps
    end
  end
end
