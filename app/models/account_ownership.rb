class AccountOwnership < ApplicationRecord
  belongs_to :user
  belongs_to :account
end
