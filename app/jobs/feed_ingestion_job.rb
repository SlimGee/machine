class FeedIngestionJob < ApplicationJob
  queue_as :feeds

  def perform(feed_config = nil)
    service = FeedIngestionService.new

    if feed_config
      # Ingest a specific feed
      result = service.ingest_feed(feed_config)
      Rails.logger.info("Ingested feed #{feed_config["feed_name"]}: created=#{result[:created]}, updated=#{result[:updated]}")
    else
      # Ingest all feeds
      result = service.ingest_all_feeds
      Rails.logger.info("Ingested all feeds: processed=#{result[:processed]}, " +
                        "failed=#{result[:failed]}, created=#{result[:indicators_created]}, " +
                        "updated=#{result[:indicators_updated]}")
    end
  end
end
