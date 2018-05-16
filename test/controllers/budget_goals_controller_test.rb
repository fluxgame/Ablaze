require 'test_helper'

class BudgetGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @budget_goal = budget_goals(:one)
  end

  test "should get index" do
    get budget_goals_url
    assert_response :success
  end

  test "should get new" do
    get new_budget_goal_url
    assert_response :success
  end

  test "should create budget_goal" do
    assert_difference('BudgetGoal.count') do
      post budget_goals_url, params: { budget_goal: { budgeted_amount: @budget_goal.budgeted_amount, name: @budget_goal.name, user_id: @budget_goal.user_id } }
    end

    assert_redirected_to budget_goal_url(BudgetGoal.last)
  end

  test "should show budget_goal" do
    get budget_goal_url(@budget_goal)
    assert_response :success
  end

  test "should get edit" do
    get edit_budget_goal_url(@budget_goal)
    assert_response :success
  end

  test "should update budget_goal" do
    patch budget_goal_url(@budget_goal), params: { budget_goal: { budgeted_amount: @budget_goal.budgeted_amount, name: @budget_goal.name, user_id: @budget_goal.user_id } }
    assert_redirected_to budget_goal_url(@budget_goal)
  end

  test "should destroy budget_goal" do
    assert_difference('BudgetGoal.count', -1) do
      delete budget_goal_url(@budget_goal)
    end

    assert_redirected_to budget_goals_url
  end
end
