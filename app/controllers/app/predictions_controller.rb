# frozen_string_literal: true

module App
  class PredictionsController < ApplicationController
    before_action :set_prediction, only: %i[show edit update destroy]
    before_action :set_query_params, only: %i[index]

    # GET /app/predictions or /app/predictions.json
    def index
      query = Prediction.order(created_at: :desc)

      query = query.where(threat_actor_id: @threat_actor.id) if @threat_actor.present?

      query = query.where(host_id: @host.id) if @host.present?

      @predictions = query.page(params[:page]).per(13)
    end

    # GET /app/predictions/1 or /app/predictions/1.json
    def show; end

    # GET /app/predictions/new
    def new
      @prediction = Prediction.new
    end

    # GET /app/predictions/1/edit
    def edit; end

    # POST /app/predictions or /app/predictions.json
    def create
      @prediction = Prediction.new(prediction_params)

      respond_to do |format|
        if @prediction.save
          format.html { redirect_to [:app, @prediction], notice: 'Prediction was successfully created.' }
          format.json { render :show, status: :created, location: @prediction }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @prediction.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /app/predictions/1 or /app/predictions/1.json
    def update
      respond_to do |format|
        if @prediction.update(prediction_params)
          format.html { redirect_to [:app, @prediction], notice: 'Prediction was successfully updated.' }
          format.json { render :show, status: :ok, location: @prediction }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @prediction.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /app/predictions/1 or /app/predictions/1.json
    def destroy
      @prediction.destroy!

      respond_to do |format|
        format.html do
          redirect_to app_predictions_path, status: :see_other, notice: 'Prediction was successfully destroyed.'
        end
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_prediction
      @prediction = Prediction.find(params.expect(:id))
    end

    def set_query_params
      @threat_actor = ThreatActor.find(params[:threat_actor_id]) if params[:threat_actor_id].present?
      @host = Host.find(params[:host_id])  if params[:host_id].present?
    end

    # Only allow a list of trusted parameters through.
    def prediction_params
      params.expect(prediction: %i[host_id threat_actor_id context confidence])
    end
  end
end
