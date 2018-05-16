class LedgerEntriesController < ApplicationController
  # before_action :set_transaction, only: [:create]
  # before_action :set_ledger_entry, only: [:toggle_cleared, :edit, :update, :destroy]
  #
  # def edit
  # end
  #
  # def update
  #   respond_to do |format|
  #     params = ledger_entries_params
  #     params = ledger_entries_params.merge(cleared: @ledger_entry.cleared) if ledger_entries_params[:cleared].nil?
  #
  #     if @ledger_entry.update(params)
  #       format.html { redirect_to @ledger_entry.parent_transaction, notice: 'Ledger Entry was successfully updated.' }
  #       format.json { render json: @ledger_entry, status: :ok }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @ledger_entry.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  #
  # def create
  #   respond_to do |format|
  #     params = ledger_entries_params
  #     params = ledger_entries_params.merge(cleared: false) if ledger_entries_params[:cleared].nil?
  #
  #     if @transaction.ledger_entries.create! params
  #       format.html { redirect_to @transaction }
  #       format.json { render json: @ledger_entry, status: :ok }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @ledger_entry.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  #
  # # DELETE /ledger_entries/1
  # # DELETE /ledger_entries/1.json
  # def destroy
  #   if @ledger_entry.account_reconciliation_id.nil?
  #     @ledger_entry.destroy
  #     respond_to do |format|
  #       format.html { redirect_to @ledger_entry.parent_transaction, notice: 'Ledger entry was successfully destroyed.' }
  #       format.json { head :no_content }
  #     end
  #   else
  #     respond_to do |format|
  #       format.html { redirect_to @ledger_entry.parent_transaction, notice: "Ledger entry is reconciled. Can't delete." }
  #       format.json { render json: @ledger_entry.errors, status: "constraint failed" }
  #     end
  #   end
  # end
  #
  
  before_action :set_ledger_entry, only: [:toggle_cleared]
  
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

  # def set_transaction
  #   @transaction = Transaction.find(params[:transaction_id])
  # end
  
  # def ledger_entries_params
  #   params.required(:ledger_entry).permit(:account_id, :budget_goal_id, :debit, :credit, :cleared, :date)
  # end
end
