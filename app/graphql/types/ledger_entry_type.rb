Types::LedgerEntryType = GraphQL::ObjectType.define do
  interfaces [ActiveRecordInterface]
  name 'LedgerEntry'

end
