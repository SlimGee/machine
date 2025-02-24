class Ingestion::ThreatFeeds::AbuseipDb < Ingestion::ThreatFeeds::Collector
  def handle
    url = "https://api.abuseipdb.com/api/v2/blacklist"
    conn = Faraday.new(url: url) do |faraday|
      faraday.request :json
      faraday.response :json
      # faraday.response :logger
      faraday.headers["Key"] = Rails.application.credentials.dig(:abuseipdb, :key)
    end

    response = conn.get

    puts response.body.to_json
  end
end
