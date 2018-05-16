class CreateScheduledTransactions < ApplicationJob
  queue_as :default

  def perform(*args)
    Transaction.where.not(repeat_frequency: nil).each do |st| st.create_next_occurence end
    User.all.each do |u| u.update_reserved_amount end
  end
end
