class AddReportData < ActiveRecord::Migration[5.2]
  def change
    create_table :report_data do |t|
	    t.references :user, foreign_key: true, :null => false
	    t.date :date, :null => false
      t.float :average_rate_of_return
      t.float :annual_savings
      t.float :annual_post_fi_spending
      t.float :net_worth
      
      t.timestamps
    end

	  add_index :report_data, [:user_id, :date], unique: true, name: "user_id_date_index"
  end
end
