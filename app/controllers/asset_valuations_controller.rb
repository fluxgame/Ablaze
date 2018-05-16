class AssetValuationsController < ApplicationController
  before_action :set_asset_valuation, only: [:show, :edit, :update, :destroy]

  # GET /asset_valuations
  # GET /asset_valuations.json
  def index
    @asset_valuations = AssetValuation.all
  end

  # GET /asset_valuations/1
  # GET /asset_valuations/1.json
  def show
  end

  # GET /asset_valuations/new
  def new
    @asset_valuation = AssetValuation.new
  end

  # GET /asset_valuations/1/edit
  def edit
  end

  # POST /asset_valuations
  # POST /asset_valuations.json
  def create
    @asset_valuation = AssetValuation.new(asset_valuation_params)

    respond_to do |format|
      if @asset_valuation.save
        format.html { redirect_to @asset_valuation, notice: 'Asset valuation was successfully created.' }
        format.json { render :show, status: :created, location: @asset_valuation }
      else
        format.html { render :new }
        format.json { render json: @asset_valuation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /asset_valuations/1
  # PATCH/PUT /asset_valuations/1.json
  def update
    respond_to do |format|
      if @asset_valuation.update(asset_valuation_params)
        format.html { redirect_to @asset_valuation, notice: 'Asset valuation was successfully updated.' }
        format.json { render :show, status: :ok, location: @asset_valuation }
      else
        format.html { render :edit }
        format.json { render json: @asset_valuation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /asset_valuations/1
  # DELETE /asset_valuations/1.json
  def destroy
    @asset_valuation.destroy
    respond_to do |format|
      format.html { redirect_to asset_valuations_url, notice: 'Asset valuation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_asset_valuation
      @asset_valuation = AssetValuation.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def asset_valuation_params
      params.require(:asset_valuation).permit(:date, :asset_type_id, :valuation_asset_type_id, :amount)
    end
end
