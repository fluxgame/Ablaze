class AddTaxRelatedToLedgerEntry < ActiveRecord::Migration[5.2]
  def change
    add_column :ledger_entries, :tax_related, :boolean , :null => false, :default => false
  end
end
