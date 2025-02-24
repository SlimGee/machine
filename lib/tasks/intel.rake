namespace :intel do
  task gather: :environment do
    Ingestion::ThreatFeeds::Collector.collect
  end
end
