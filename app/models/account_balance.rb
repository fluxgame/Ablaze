class AccountBalance < ApplicationRecord
  belongs_to :account, touch: true
  has_many :ledger_entries

#  def readonly?() true end
end
