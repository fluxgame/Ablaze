class AssetValuation < ApplicationRecord
  belongs_to :asset_type, touch: true
  belongs_to :valuation_asset_type, class_name: 'AssetType', touch: true
end
