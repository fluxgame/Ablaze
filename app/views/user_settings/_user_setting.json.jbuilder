json.extract! user_setting, :id, :home_asset_type_id, :withdrawal_rate, :goal_savings_rate, :created_at, :updated_at
json.url user_setting_url(user_setting, format: :json)
