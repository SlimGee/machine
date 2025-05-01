class App::ThreatActorsController < ApplicationController
  before_action :set_threat_actor, only: %i[ show edit update destroy ]

  # GET /app/threat_actors or /app/threat_actors.json
  def index
    @threat_actors = ThreatActor.order(created_at: :desc).page(params[:page]).per(13)
  end

  # GET /app/threat_actors/1 or /app/threat_actors/1.json
  def show
  end

  # GET /app/threat_actors/new
  def new
    @threat_actor = ThreatActor.new
  end

  # GET /app/threat_actors/1/edit
  def edit
  end

  # POST /app/threat_actors or /app/threat_actors.json
  def create
    @threat_actor = ThreatActor.new(threat_actor_params)

    respond_to do |format|
      if @threat_actor.save
        format.html { redirect_to [:app, @threat_actor], notice: "Threat actor was successfully created." }
        format.json { render :show, status: :created, location: @threat_actor }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @threat_actor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /app/threat_actors/1 or /app/threat_actors/1.json
  def update
    respond_to do |format|
      if @threat_actor.update(threat_actor_params)
        format.html { redirect_to [:app, @threat_actor], notice: "Threat actor was successfully updated." }
        format.json { render :show, status: :ok, location: @threat_actor }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @threat_actor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app/threat_actors/1 or /app/threat_actors/1.json
  def destroy
    @threat_actor.destroy!

    respond_to do |format|
      format.html { redirect_to app_threat_actors_path, status: :see_other, notice: "Threat actor was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_threat_actor
      @threat_actor = ThreatActor.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def threat_actor_params
      params.expect(threat_actor: [ :name, :description, :first_seen, :last_seen ])
    end
end
