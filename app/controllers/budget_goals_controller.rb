class BudgetGoalsController < ApplicationController
  before_action :set_budget_goal, only: [:show, :edit, :update, :destroy]

  # GET /budget_goals
  # GET /budget_goals.json
  def index
    @budget_goals = BudgetGoal.where(user_id: current_user.id)

    scheduled_amounts = []
    Transaction.where(user_id: current_user.id).where.not(repeat_frequency: nil).each do |st|
      amount = 0
      st.ledger_entries.each do |le|
        if le.account.spending_account?
            amount += le.amount_in(current_user.home_asset_type)
        end
      end
      
      scheduled_amounts.push({amount: amount, schedule: st.schedule})
    end
    
    @days = []
    running_total = current_user.spendable_at_start_of_today - current_user.amount_budgeted
    for i in 0..364
      date = Date.today + (i+1).days
      amount = 0
      scheduled_amounts.each do |sa|
        if sa[:schedule].occurs_on?(date)
          amount += sa[:amount]
        end
      end
      
      if amount != 0
        running_total += amount
        @days.push({date: date, amount: amount, running_total: running_total})
      end
    end
    
    @days.sort! { |a, z| a[:running_total] <=> z[:running_total] }
    
    @minimums = [@days[0]]
    @days.shift
    
    @days.each do |day|
      @minimums.push(day) if day[:date] > @minimums.last[:date]
    end
     
    i = 1
    @minimums.each do |min|
      if @minimums[i].present?
        min[:days_till_next] = (@minimums[i][:date] - min[:date]).to_i
        min[:available_to_spend] = (min[:running_total] / min[:days_till_next]).to_f
        i += 1
      end
    end
    
    @minimums.pop
    
    @minimums.sort! { |a, z| a[:available_to_spend] <=> z[:available_to_spend] }
    @available_to_budget = (@minimums[0][:available_to_spend] - 50) * @minimums[0][:days_till_next]
  end

  # GET /budget_goals/1
  # GET /budget_goals/1.json
  def show
  end

  # GET /budget_goals/new
  def new
    @budget_goal = BudgetGoal.new
  end

  # GET /budget_goals/1/edit
  def edit
  end

  # POST /budget_goals
  # POST /budget_goals.json
  def create
    @budget_goal = BudgetGoal.new(budget_goal_params)
    @budget_goal.user_id = current_user.id

    respond_to do |format|
      if @budget_goal.save
        format.html { redirect_to @budget_goal, notice: 'Budget goal was successfully created.' }
        format.json { render :show, status: :created, location: @budget_goal }
      else
        format.html { render :new }
        format.json { render json: @budget_goal.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /budget_goals/1
  # PATCH/PUT /budget_goals/1.json
  def update
    respond_to do |format|
      if @budget_goal.update(budget_goal_params)
        format.html { redirect_to @budget_goal, notice: 'Budget goal was successfully updated.' }
        format.json { render :show, status: :ok, location: @budget_goal }
      else
        format.html { render :edit }
        format.json { render json: @budget_goal.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /budget_goals/1
  # DELETE /budget_goals/1.json
  def destroy
    @budget_goal.destroy
    respond_to do |format|
      format.html { redirect_to budget_goals_url, notice: 'Budget goal was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_budget_goal
      @budget_goal = BudgetGoal.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def budget_goal_params
      params.require(:budget_goal).permit(:budgeted_amount, :name, :user_id)
    end
end
