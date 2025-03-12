module FeedIngestable
  extend ActiveSupport::Concern

  def self.feed_types
    {
      txt: Feeds::TextFeedParser,
      csv: Feeds::CsvFeedParser,
      json: Feeds::JsonFeedParser
      # Add more feed types as needed
    }
  end
end
