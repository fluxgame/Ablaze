require 'test_helper'

class AccountTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_type = account_types(:one)
  end

  test "should get index" do
    get account_types_url
    assert_response :success
  end

  test "should get new" do
    get new_account_type_url
    assert_response :success
  end

  test "should create account_type" do
    assert_difference('AccountType.count') do
      post account_types_url, params: { account_type: { master_account_type: @account_type.master_account_type, name: @account_type.name } }
    end

    assert_redirected_to account_type_url(AccountType.last)
  end

  test "should show account_type" do
    get account_type_url(@account_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_account_type_url(@account_type)
    assert_response :success
  end

  test "should update account_type" do
    patch account_type_url(@account_type), params: { account_type: { master_account_type: @account_type.master_account_type, name: @account_type.name } }
    assert_redirected_to account_type_url(@account_type)
  end

  test "should destroy account_type" do
    assert_difference('AccountType.count', -1) do
      delete account_type_url(@account_type)
    end

    assert_redirected_to account_types_url
  end
end
