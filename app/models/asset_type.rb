require 'open-uri'
require 'csv'

class AssetType < ApplicationRecord
  validates_presence_of :name, :abbreviation
  has_many :asset_valuations
  
  def exchange(amount, in_asset_type, on_date = Date.today)
    if amount.nil? || amount == 0
      return amount
    end
    
    valuation = in_asset_type.id == self.id ? 1 : 
      Rails.cache.fetch("#{cache_key}/value_in_" + in_asset_type.id.to_s + "_on_" + on_date.to_s, expires_in: 15.minutes) {
        valuation = AssetValuation.where(asset_type: self.id)
                                  .where(valuation_asset_type: in_asset_type.id)
                                  .where("date <= ?", DateTime.parse(on_date.to_s))
                                  .order(date: :desc).first                                  
    }

    valuation = valuation.amount if valuation.is_a?(AssetValuation)
    return nil if valuation.nil?
    return (amount * valuation).round(in_asset_type.precision)
  end
  
  def to_currency(amount)
    return ActionController::Base.helpers.number_to_currency(amount, precision: self.precision, unit: self.currency_symbol)
  end
  
  def fetch_valuations
    if self.fetch_prices
      usd = AssetType.where(abbreviation: "USD").first
    
      if !usd.nil?
        stock_api = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&apikey=0LTH8KZDGWMXMZZR&datatype=csv&symbol="
        puts stock_api + self.abbreviation
        CSV.new(open(stock_api + self.abbreviation), :headers => true, :return_headers => false).each do |row|
          date = DateTime.parse(row[0])
      
          exists = AssetValuation.where(asset_type: self.id).where(valuation_asset_type: usd.id).where("date = ?", date).count > 0
      
          if !exists
            AssetValuation.create!(date: date, asset_type_id: self.id, valuation_asset_type_id: usd.id, amount: row[4].to_f)
          end
        end      
      end
    end
  end
  
end
