class App::IndicatorsController < App::ApplicationController
  before_action :set_indicator, only: %i[show edit update destroy]

  # GET /app/indicators or /app/indicators.json
  def index
    @indicators = Indicator.order(created_at: :desc).page(params[:page]).per(13)
  end

  # GET /app/indicators/1 or /app/indicators/1.json
  def show
  end

  # GET /app/indicators/new
  def new
    @indicator = Indicator.new
  end

  # GET /app/indicators/1/edit
  def edit
  end

  # POST /app/indicators or /app/indicators.json
  def create
    @indicator = Indicator.new(indicator_params)

    respond_to do |format|
      if @indicator.save
        format.html { redirect_to [ :app, @indicator ], notice: "Indicator was successfully created." }
        format.json { render :show, status: :created, location: @indicator }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @indicator.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /app/indicators/1 or /app/indicators/1.json
  def update
    respond_to do |format|
      if @indicator.update(indicator_params)
        format.html { redirect_to [ :app, @indicator ], notice: "Indicator was successfully updated." }
        format.json { render :show, status: :ok, location: @indicator }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @indicator.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app/indicators/1 or /app/indicators/1.json
  def destroy
    @indicator.destroy!

    respond_to do |format|
      format.html { redirect_to app_indicators_path, status: :see_other, notice: "Indicator was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_indicator
      @indicator = Indicator.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def indicator_params
      params.expect(indicator: [ :indicator_type, :value, :confidence, :first_seen, :last_seen, :source_id ])
    end
end
