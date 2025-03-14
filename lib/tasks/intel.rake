namespace :intel do
  task gather: :environment do
    Ingestion::ThreatFeeds::Collector.collect
  end

  task process: :environment do
    Rails.logger.info("Starting autonomous analysis")

    # Run the autonomous analyzer
    Analysis::Engine.analyze_new_indicators
  end
end
