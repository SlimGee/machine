class Ingestion::Feeds
  def initialize(feeds_directory = Rails.root.join('db/feeds.d'))
    @feeds_directory = feeds_directory
  end

  def ingest_all_feeds
    feed_configs = load_feed_configs
    results = {
      processed: 0,
      failed: 0,
      indicators_created: 0,
      indicators_updated: 0
    }

    feed_configs.each do |feed_config|
      puts "Ingesting feed #{feed_config['feed_name']}..."
      begin
        result = ingest_feed(feed_config)
        puts "Created: #{result[:created]}, Updated: #{result[:updated]}"
        puts result.inspect

        results[:processed] += 1
        results[:indicators_created] += result[:created]
        results[:indicators_updated] += result[:updated]
      rescue StandardError => e
        puts e.message
        Rails.logger.error("Error ingesting feed #{feed_config['feed_name']}: #{e.message}")
        results[:failed] += 1
      end
    end

    results
  end

  def ingest_feed(feed_config)
    parser = Feeds::FeedParser.for(feed_config)
    return { created: 0, updated: 0 } if parser.nil?

    indicators = parser.fetch_and_parse
    result = { created: 0, updated: 0 }

    # Find or create the source
    source = Source.find_or_create_by(name: feed_config['feed_name']) do |s|
      s.source_type = feed_config['feed_type']
      s.url = feed_config['feed_url']
      s.reliability = 70 # Default reliability score
      s.last_update = Time.now
    end

    # Update the source's last_update time
    source.update(last_update: Time.now)

    # Process indicators
    indicators.each do |indicator_data|
      indicator = Indicator.find_or_initialize_by(
        indicator_type: indicator_data[:type],
        value: indicator_data[:value],
        source_id: source.id
      )

      if indicator.new_record?
        indicator.confidence = indicator_data[:confidence]
        indicator.first_seen = indicator_data[:first_seen]
        indicator.last_seen = indicator_data[:last_seen]
        indicator.save
        result[:created] += 1
      else
        indicator.last_seen = Time.now
        indicator.analysed = false
        indicator.save
        result[:updated] += 1
      end
    end

    result
  end

  private

  def load_feed_configs
    configs = []

    Dir.glob(File.join(@feeds_directory, '*.json')).each do |file|
      json_data = JSON.parse(File.read(file))
      configs += json_data['feeds'] if json_data['feeds'].is_a?(Array)
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing feed config file #{file}: #{e.message}")
    end

    configs
  end
end
