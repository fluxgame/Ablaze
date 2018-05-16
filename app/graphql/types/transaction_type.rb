Types::TransactionType = GraphQL::ObjectType.define do
  interfaces [ActiveRecordInterface]
  name 'Transaction'

  field :repeat_feequency, !types.String
  field :description, !types.String

  field :ledger_entries, !types[Types::LedgerEntryType]
end
