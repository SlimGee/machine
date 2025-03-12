class Feeds::CsvFeedParser
  require "csv"
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

    CSV.parse(content, headers: true) do |row|
      # Map source field to destination field based on config
      indicator_data = {}

      if config["field_mapping"]["source"].any?
        config["field_mapping"]["source"].each_with_index do |source_field, index|
          dest_field = config["field_mapping"]["destination"][index]
          indicator_data[dest_field] = row[source_field] if row[source_field]
        end
      else
        # Simple case - just get the first field
        indicator_data["value"] = row.fields.first&.strip
      end

      next if indicator_data["value"].nil? || indicator_data["value"].empty?

      indicators << {
        type: config["indicator_type"],
        value: indicator_data["value"],
        confidence: indicator_data["confidence"] || 75,
        first_seen: Time.now,
        last_seen: Time.now,
        source_name: config["feed_name"],
        source_url: config["feed_url"]
      }
    end

    indicators
  end
end
