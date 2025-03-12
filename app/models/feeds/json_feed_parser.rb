class Feeds::JsonFeedParser
  require "net/http"
  require "uri"
  require "json"

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

    begin
      data = JSON.parse(content)

      # Extract indicators based on field mapping
      if config["field_mapping"]["source"].any?
        # Navigate to the indicator items (could be nested)
        items = data
        path = config["field_mapping"]["path"] || []

        path.each do |segment|
          items = items[segment] if items.is_a?(Hash) || items.is_a?(Array)
        end

        if items.is_a?(Array)
          items.each do |item|
            indicator_data = {}

            config["field_mapping"]["source"].each_with_index do |source_field, index|
              dest_field = config["field_mapping"]["destination"][index]
              indicator_data[dest_field] = item[source_field] if item[source_field]
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
        end
      end
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing JSON feed #{config["feed_name"]}: #{e.message}")
    end

    indicators
  end
end
