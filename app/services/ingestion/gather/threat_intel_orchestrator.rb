class Ingestion::Gather::ThreatIntelOrchestrator
  def initialize
    @logger = Logger.new('orchestrator.log')
    @intel_collector = Ingestion::Gather::ThreatIntelCollector.new
    @specialized_collector = Ingestion::Gather::SpecializedThreatCollector.new(@intel_collector)

    # Configuration - should be loaded from environment or config file
    @config = {
      misp: {
        api_key: Rails.application.credentials.dig(:misp, :api_key),
        base_url: 'https://misp.example.org',
      },
      otx: {
        api_key: Rails.application.credentials.dig(:otx, :api_key),
      },
      twitter: {
        api_key: Rails.application.credentials.dig(:twitter, :api_key),
        api_secret: Rails.application.credentials.dig(:twitter, :api_secret),
      },
      honeypot_dir: '/var/log/honeypot',
      firewall_log: '/var/log/firewall.log',
      collection_interval: 86_400, # daily
    }
  end

  def collect_all_data
    @logger.info('Starting comprehensive threat intel collection')

    # Collect standard threat intel
    # begin
    #   @intel_collector.collect_misp_data(@config[:misp][:api_key], @config[:misp][:base_url])
    # rescue StandardError => e
    # j   @logger.error("MISP collection failed: #{e.message}")
    # end

    #  begin
    #    @intel_collector.collect_otx_data(@config[:otx][:api_key])
    #  rescue StandardError => e
    #      @logger.error("OTX collection failed: #{e.message}")
    #    end

    begin
    #  @intel_collector.collect_nvd_data(30) # Last 30 days
    rescue StandardError => e
      @logger.error("NVD collection failed: #{e.message}")
    end

    # Parse logs if available
    # @intel_collector.parse_firewall_logs(@config[:firewall_log]) if File.exist?(@config[:firewall_log])

    # Collect honeypot data if directory exists
    # @intel_collector.collect_honeypot_data(@config[:honeypot_dir]) if Dir.exist?(@config[:honeypot_dir])

    # Collect specialized threat intel
    begin
      @specialized_collector.collect_cti_feeds
    rescue StandardError => e
      @logger.error("CTI feeds collection failed: #{e.message}")
    end

    #  begin
    #    @specialized_collector.collect_security_mailinglists
    #  rescue StandardError => e
    #    @logger.error("Security mailing list collection failed: #{e.message}")
    #  end

    #  begin
    #    @specialized_collector.collect_twitter_osint(
    #      @config[:twitter][:api_key],
    #      @config[:twitter][:api_secret],
    #    )
    #  rescue StandardError => e
    #    @logger.error("Twitter OSINT collection failed: #{e.message}")
    #  end

    @logger.info('Data collection complete, preparing datasets')

    # Prepare datasets for each model
    begin
      # Prepare standard features
      logs = begin
        JSON.parse(File.read("threat_data/parsed_fw_logs_#{Time.now.strftime('%Y%m%d')}.json"))
      rescue StandardError
        []
      end
      @intel_collector.prepare_time_series_features(logs, 'hourly')
      @intel_collector.prepare_classification_features(logs)

      # Prepare combined dataset
      @intel_collector.prepare_combined_dataset

      # Prepare specialized features
      @specialized_collector.prepare_specialized_features

      @logger.info('Dataset preparation complete')
    rescue StandardError => e
      @logger.error("Dataset preparation failed: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
    end
  end

  # Run periodic collection
  def start_scheduled_collection
    @logger.info("Starting scheduled collection every #{@config[:collection_interval]} seconds")

    loop do
      collect_all_data
      @logger.info("Sleeping for #{@config[:collection_interval]} seconds")
      sleep @config[:collection_interval]
    end
  end

  # Generate final training datasets for The Machine
  def prepare_final_datasets
    @logger.info('Preparing final datasets for The Machine')

    data_dir = 'threat_data/final/'
    Dir.mkdir(data_dir) unless Dir.exist?(data_dir)

    # Combine time series data
    begin
      prophet_data = CSV.read("threat_data/prophet_dataset_#{Time.now.strftime('%Y%m%d')}.csv", headers: true)

      # Add additional external factors if available

      # Save final time series dataset
      CSV.open("#{data_dir}the_machine_timeseries_dataset.csv", 'w') do |csv|
        csv << prophet_data.headers
        prophet_data.each do |row|
          csv << row
        end
      end

      @logger.info("Prepared time series dataset with #{prophet_data.size} rows")
    rescue StandardError => e
      @logger.error("Error preparing time series dataset: #{e.message}")
    end

    # Combine classification data
    begin
      xgboost_data = CSV.read("threat_data/xgboost_dataset_#{Time.now.strftime('%Y%m%d')}.csv", headers: true)

      # Save final classification dataset
      CSV.open("#{data_dir}the_machine_classification_dataset.csv", 'w') do |csv|
        csv << xgboost_data.headers
        xgboost_data.each do |row|
          csv << row
        end
      end

      @logger.info("Prepared classification dataset with #{xgboost_data.size} rows")
    rescue StandardError => e
      @logger.error("Error preparing classification dataset: #{e.message}")
    end

    # Combine anomaly detection data
    begin
      isolation_forest_data = CSV.read("threat_data/isolation_forest_dataset_#{Time.now.strftime('%Y%m%d')}.csv",
        headers: true,)

      # Save final anomaly detection dataset
      CSV.open("#{data_dir}the_machine_anomaly_dataset.csv", 'w') do |csv|
        csv << isolation_forest_data.headers
        isolation_forest_data.each do |row|
          csv << row
        end
      end

      @logger.info("Prepared anomaly detection dataset with #{isolation_forest_data.size} rows")
    rescue StandardError => e
      @logger.error("Error preparing anomaly detection dataset: #{e.message}")
    end

    # Prepare LSTM sequence data
    begin
      lstm_data = JSON.parse(File.read("threat_data/lstm_sequence_data_#{Time.now.strftime('%Y%m%d')}.json"))

      # Save final LSTM dataset
      File.write("#{data_dir}the_machine_sequence_dataset.json", lstm_data.to_json)

      @logger.info("Prepared LSTM sequence dataset with #{lstm_data.size} sequences")
    rescue StandardError => e
      @logger.error("Error preparing LSTM dataset: #{e.message}")
    end

    # Prepare GNN graph data
    begin
      gnn_data = JSON.parse(File.read("threat_data/gnn_graph_data_#{Time.now.strftime('%Y%m%d')}.json"))

      # Save final GNN dataset
      File.write("#{data_dir}the_machine_graph_dataset.json", gnn_data.to_json)

      @logger.info("Prepared GNN graph dataset with #{gnn_data['nodes']['ip'].size} nodes")
    rescue StandardError => e
      @logger.error("Error preparing GNN dataset: #{e.message}")
    end

    @logger.info('All final datasets prepared for The Machine')
  end
end
