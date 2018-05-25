class AccountsController < ApplicationController
  before_action :set_account, only: [:show, :edit, :update, :destroy, :reconcile, :transfer]

  # GET /accounts
  # GET /accounts.json
  def index
    @accounts = Account.where(user_id: current_user.id).joins(:account_type)
        .merge(AccountType.order(:master_account_type, :name))
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show
    if params[:show_reconciled].nil?
      @ledger_entries = LedgerEntry.where(account_id: @account.id, account_reconciliation_id: nil).order(date: :asc)
    else
      @ledger_entries = LedgerEntry.where(account_id: @account.id).order(date: :asc)
    end
  end

  # GET /accounts/new
  def new
    @account = Account.new
  end

  # GET /accounts/1/edit
  def edit
  end
  
  def reconcile
    if LedgerEntry.where(account_id: @account.id, cleared: true, account_reconciliation_id: nil).count > 0
      account_reconciliation = @account.account_reconciliations.create! balance: @account.cleared_balance, date: params[:reconcile_date]
      LedgerEntry.where(account_id: @account.id, cleared: true, account_reconciliation_id: nil).update_all(account_reconciliation_id: account_reconciliation.id)
    end
    redirect_to @account
  end
  
  def transfer
    @dest_account = Account.find(params[:dest_account_id])
    date = params[:date]
    shares = params[:shares].to_f
    price = params[:price].to_f

    
    transaction = Transaction.create!(user_id: current_user.id, description: "Buy " + shares.to_s + " shares")
    
    if shares < 0
      debit_account = @dest_account
      credit_account = @account
      debit_amount = shares * price * -1
      credit_amount = shares * -1
    else
      credit_account = @dest_account
      debit_account = @account
      credit_amount = shares * price
      debit_amount = shares
    end      
    
    transaction.ledger_entries.create!(date: date, cleared: false, account_id: credit_account.id, credit: credit_amount)
    transaction.ledger_entries.create!(date: date, cleared: false, account_id: debit_account.id, debit: debit_amount)

    if price != 1
      AssetValuation.create!(date: date, asset_type_id: @account.asset_type.id, valuation_asset_type_id: @dest_account.asset_type.id, amount: price)
    end
    
    redirect_to @account
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(account_params)
    @account.user_id = current_user.id
    @account.save
    
    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: 'Account was successfully created.' }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /accounts/1
  # PATCH/PUT /accounts/1.json
  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: 'Account was successfully updated.' }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    @account.destroy
    respond_to do |format|
      format.html { redirect_to accounts_url, notice: 'Account was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_account
      @account = Account.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def account_params
      params.require(:account).permit(:name, :expected_annual_return, :asset_type_id, :account_type_id, :mobile, :fi_budget)
    end
end
