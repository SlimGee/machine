namespace :feeds do
  desc "Ingest all configured threat feeds"
  task ingest: :environment do
    puts "Starting feed ingestion..."
    result = Ingestion::Feeds.new.ingest_all_feeds
    puts "Feed ingestion complete."
    puts "Processed: #{result[:processed]} feeds"
    puts "Failed: #{result[:failed]} feeds"
    puts "Created: #{result[:indicators_created]} indicators"
    puts "Updated: #{result[:indicators_updated]} indicators"
  end

  desc "Schedule recurring feed ingestion jobs"
  task schedule: :environment do
    service = FeedIngestionService.new
    feed_configs = service.send(:load_feed_configs)

    puts "Scheduling feed ingestion jobs..."

    feed_configs.each do |feed_config|
      interval = feed_config["check_interval"]&.first || 24 # Default to 24 hours

      # Schedule the job to run at the specified interval
      FeedIngestionJob.set(wait: interval.hours).perform_later(feed_config)

      puts "Scheduled feed '#{feed_config["feed_name"]}' to run every #{interval} hours."
    end

    puts "All feed ingestion jobs scheduled."
  end
end
