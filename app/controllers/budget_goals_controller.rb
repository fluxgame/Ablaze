class BudgetGoalsController < ApplicationController
  before_action :set_budget_goal, only: [:show, :edit, :update, :destroy]

  # GET /budget_goals
  # GET /budget_goals.json
  def index
    @accounts = Account.joins(:budget_goals).select("DISTINCT accounts.*").where(user_id: current_user.id)
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
      params.require(:budget_goal).permit(:budgeted_amount, :name, :user_id, :account_id, :remaining_amount)
    end
end
