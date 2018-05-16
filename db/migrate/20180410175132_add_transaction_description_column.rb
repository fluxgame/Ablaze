class AddTransactionDescriptionColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :description, :string
  end
end
