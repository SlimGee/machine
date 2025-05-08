# frozen_string_literal: true

module App
  class HostsController < ApplicationController
    before_action :set_host, only: %i[show edit update destroy]

    # GET /app/hosts or /app/hosts.json
    def index
      @hosts = Host.order(created_at: :desc).page(params[:page]).per(13)
    end

    # GET /app/hosts/1 or /app/hosts/1.json
    def show; end

    # GET /app/hosts/new
    def new
      @host = Host.new
    end

    # GET /app/hosts/1/edit
    def edit; end

    # POST /app/hosts or /app/hosts.json
    def create
      @host = Host.new(host_params)

      respond_to do |format|
        if @host.save
          format.html { redirect_to [ :app, @host ], notice: "Host was successfully created." }
          format.json { render :show, status: :created, location: @host }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @host.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /app/hosts/1 or /app/hosts/1.json
    def update
      respond_to do |format|
        if @host.update(host_params)
          format.html { redirect_to [ :app, @host ], notice: "Host was successfully updated." }
          format.json { render :show, status: :ok, location: @host }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @host.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /app/hosts/1 or /app/hosts/1.json
    def destroy
      @host.destroy!

      respond_to do |format|
        format.html { redirect_to app_hosts_path, status: :see_other, notice: "Host was successfully destroyed." }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_host
      @host = Host.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def host_params
      params.expect(host: [ :ip ])
    end
  end
end
