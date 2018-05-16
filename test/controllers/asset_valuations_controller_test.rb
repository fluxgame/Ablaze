require 'test_helper'

class AssetValuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @asset_valuation = asset_valuations(:one)
  end

  test "should get index" do
    get asset_valuations_url
    assert_response :success
  end

  test "should get new" do
    get new_asset_valuation_url
    assert_response :success
  end

  test "should create asset_valuation" do
    assert_difference('AssetValuation.count') do
      post asset_valuations_url, params: { asset_valuation: { amount: @asset_valuation.amount, asset_type_id: @asset_valuation.asset_type_id, date: @asset_valuation.date, valuation_asset_type_id: @asset_valuation.valuation_asset_type_id } }
    end

    assert_redirected_to asset_valuation_url(AssetValuation.last)
  end

  test "should show asset_valuation" do
    get asset_valuation_url(@asset_valuation)
    assert_response :success
  end

  test "should get edit" do
    get edit_asset_valuation_url(@asset_valuation)
    assert_response :success
  end

  test "should update asset_valuation" do
    patch asset_valuation_url(@asset_valuation), params: { asset_valuation: { amount: @asset_valuation.amount, asset_type_id: @asset_valuation.asset_type_id, date: @asset_valuation.date, valuation_asset_type_id: @asset_valuation.valuation_asset_type_id } }
    assert_redirected_to asset_valuation_url(@asset_valuation)
  end

  test "should destroy asset_valuation" do
    assert_difference('AssetValuation.count', -1) do
      delete asset_valuation_url(@asset_valuation)
    end

    assert_redirected_to asset_valuations_url
  end
end
