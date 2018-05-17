class CreateTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :transactions do |t|
      t.string :description
      t.string :repeat_frequency
      t.references :user, foreign_key: true
      t.belongs_to :prototype_transaction, foreign_key: {to_table: :transactions}

      t.timestamps
    end
  end
end
