class App::ReportsController < ApplicationController
  before_action :set_report, only: %i[show edit update destroy]

  # GET /app/reports or /app/reports.json
  def index
    @reports = Report.order(created_at: :desc).page(params[:page]).per(13)
  end

  # GET /app/reports/1 or /app/reports/1.json
  def show
  end

  # GET /app/reports/new
  def new
    @report = Report.new
  end

  # GET /app/reports/1/edit
  def edit
  end

  # POST /app/reports or /app/reports.json
  def create
    @report = Report.new(report_params)

    respond_to do |format|
      if @report.valid?
        begin
          @report = Reporting::ThreatIntelligenceReport.call @report.start_time, @report.end_time
          format.html { redirect_to [:app, @report], notice: "Report was successfully created." }
          format.json { render :show, status: :created, location: @report }
          format.turbo_stream do
            flash[:notice] = "Report was successfully created"
            render turbo_stream: turbo_stream.action(:redirect, app_report_path(@report))
          end
        rescue StandardError
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @report.errors, status: :unprocessable_entity }
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /app/reports/1 or /app/reports/1.json
  def update
    respond_to do |format|
      if @report.update(report_params)
        format.html { redirect_to [:app, @report], notice: "Report was successfully updated." }
        format.json { render :show, status: :ok, location: @report }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @report.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /app/reports/1 or /app/reports/1.json
  def destroy
    @report.destroy!

    respond_to do |format|
      format.html { redirect_to app_reports_path, status: :see_other, notice: "Report was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_report
    @report = Report.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def report_params
    params.expect(report: %i[start_time end_time])
  end
end
