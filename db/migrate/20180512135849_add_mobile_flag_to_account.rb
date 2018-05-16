class AddMobileFlagToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :mobile, :boolean
  end
end
