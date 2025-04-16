class App::SourcesController < App::ApplicationController
  before_action :set_source, only: %i[show edit update destroy]

  # GET /app/sources or /app/sources.json
  def index
    @sources = Source.order(created_at: :desc).page(params[:page]).per(12)
  end

  # GET /app/sources/1 or /app/sources/1.json
  def show
  end

  # GET /app/sources/new
  def new
    @source = Source.new
  end

  # GET /app/sources/1/edit
  def edit
  end

  # POST /app/sources or /app/sources.json
  def create
    @source = Source.new(source_params)

    respond_to do |format|
      if @source.save
        format.html { redirect_to app_sources_path, notice: "Source was successfully created." }
        format.json { render :show, status: :created, location: @source }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /app/sources/1 or /app/sources/1.json
  def update
    respond_to do |format|
      if @source.update(source_params)
        format.html { redirect_to app_sources_path, notice: "Source was successfully updated." }
        format.json { render :show, status: :ok, location: @source }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app/sources/1 or /app/sources/1.json
  def destroy
    @source.destroy!

    respond_to do |format|
      format.html { redirect_to app_sources_path, status: :see_other, notice: "Source was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_source
      @source = Source.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def source_params
      params.expect(source: [ :name, :source_type, :url, :reliability, :last_update ])
    end
end
