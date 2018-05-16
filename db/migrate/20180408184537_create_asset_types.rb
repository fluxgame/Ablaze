class CreateAssetTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :asset_types do |t|
      t.string :name, :null => false
      t.string :abbreviation, :null => false

      t.timestamps
    end
    
    add_index :asset_types, :abbreviation, unique: true
  end    
end
