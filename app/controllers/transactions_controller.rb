class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]

  # GET /transactions
  # GET /transactions.json
  def index
    @transactions = Transaction.all
  end

  def list_scheduled
    @transactions = Transaction.where.not(repeat_frequency: nil)
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
    2.times { @transaction.ledger_entries.build }
  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions
  # POST /transactions.json
  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.user_id = current_user.id

    @transaction.ledger_entries.each do |le|
      le.cleared = false if le.cleared.nil?
    end
    
    respond_to do |format|
      if @transaction.save
        format.html { redirect_to @transaction, notice: 'Transaction was successfully created.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :new }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transactions/1
  # PATCH/PUT /transactions/1.json
  def update

    respond_to do |format|
      @transaction.assign_attributes(transaction_params)
      
      @transaction.ledger_entries.each do |le|
        le.cleared = LedgerEntry.find(le.id).cleared if le.cleared.nil?
      end
      
      if @transaction.save
        format.html { redirect_to @transaction, notice: 'Transaction was successfully updated.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'Transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def update_multiple
    merged_transaction_id = params[:selected_transaction_ids][0]
    params[:selected_transaction_ids].shift
    LedgerEntry.where(transaction_id: params[:selected_transaction_ids])
        .update_all(transaction_id: merged_transaction_id) 
    Transaction.destroy(params[:selected_transaction_ids])
    redirect_to transactions_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:date, :repeat_frequency, :description, 
          ledger_entries_attributes: [:id, :account_id, :budget_goal_id, :debit, :credit, :cleared, :date, :_destroy])
    end
end
