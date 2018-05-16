class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.date :date
      t.string :repeat_frequency
      t.references :user, foreign_key: true
      t.references :prototype_transaction, index: true

      t.timestamps
    end
  end
end
