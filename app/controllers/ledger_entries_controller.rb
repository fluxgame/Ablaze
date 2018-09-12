class LedgerEntriesController < ApplicationController
  before_action :set_ledger_entry, only: [:toggle_cleared]
  
  def index
    @ledger_entries = LedgerEntry.all.order(date: :desc)
    @ledger_entries = @ledger_entries.where(account: params[:account]) if params[:account].present?
    @ledger_entries = @ledger_entries.where('date > ?', Date.today - params[:days].to_i.days) if params[:days].to_i > 0
  end

  def toggle_cleared
    respond_to do |format|
      if @ledger_entry.toggle(:cleared).save
        format.js
        format.html
      else
        format.js
        format.html
      end
    end
  end

  private
  def set_ledger_entry
    @ledger_entry = LedgerEntry.find(params[:id])
  end
end
