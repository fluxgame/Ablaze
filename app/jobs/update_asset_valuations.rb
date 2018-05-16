class UpdateAssetValuations < ApplicationJob
  queue_as :default

  def perform(*args)
    AssetType.where(fetch_prices: true).each do |at| at.fetch_valuations end
  end
end
