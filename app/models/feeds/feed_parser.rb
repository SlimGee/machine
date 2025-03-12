class Feeds::FeedParser
  def self.for(feed_config)
    parser_class = FeedIngestable.feed_types[feed_config["feed_type"].to_sym]

    if parser_class.nil?
      Rails.logger.error("Unknown feed type: #{feed_config["feed_type"]}")
      return nil
    end

    parser_class.new(feed_config)
  end
end
