class Feeds::TextFeedParser
  require "net/http"
  require "uri"

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def fetch_and_parse
    begin
      uri = URI.parse(config["feed_url"])
      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPSuccess)
        parse_content(response.body)
      else
        Rails.logger.error("Failed to fetch feed #{config["feed_name"]}: #{response.code} - #{response.message}")
        []
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching feed #{config["feed_name"]}: #{e.message}")
      []
    end
  end

  def parse_content(content)
    indicators = []

    content.each_line do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")

      indicators << {
        type: config["indicator_type"],
        value: line,
        confidence: 75, # Default confidence value
        first_seen: Time.now,
        last_seen: Time.now,
        source_name: config["feed_name"],
        source_url: config["feed_url"]
      }
    end

    indicators
  end
end
