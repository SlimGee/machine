class App::EventsController < App::ApplicationController
  before_action :set_event, only: %i[show edit update destroy]

  # GET /app/events or /app/events.json
  def index
    @events = Event.order(timestamp: :desc).page(params[:page]).per(10)
  end

  # GET /app/events/1 or /app/events/1.json
  def show
  end

  # GET /app/events/new
  def new
    @event = Event.new
  end

  # GET /app/events/1/edit
  def edit
  end

  # POST /app/events or /app/events.json
  def create
    @event = Event.new(event_params)

    respond_to do |format|
      if @event.save
        format.html { redirect_to [ :app, @event ], notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /app/events/1 or /app/events/1.json
  def update
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to [ :app, @event ], notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app/events/1 or /app/events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to app_events_path, status: :see_other, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.expect(event: [ :event_type, :timestamp, :description, :severity ])
    end
end
