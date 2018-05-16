Types::QueryType = GraphQL::ObjectType.define do
  name "Query"

  guard ->(obj, args, ctx) { !ctx[:current_user].blank? }
  field :recent_expense_transactions, !types[Types::TransactionType] do
    argument :limit, types.Int, default_value: 20, prepare: -> (limit) { [limit, 30].min }
    resolve -> (obj, args, ctx) {
      Transaction.limit(args[:limit]).merge(LedgerEntry.where.not(date: nil).order(date: :desc))
                 .includes(ledger_entries: :account).where(:accounts => {account_type_id: AccountType.expense})
    }
  end
end

