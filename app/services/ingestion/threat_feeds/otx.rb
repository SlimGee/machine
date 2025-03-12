class Ingestion::ThreatFeeds::Otx < Ingestion::ThreatFeeds::Collector
  OTX_API_BASE_URL = "https://otx.alienvault.com/api/v1/"
  PULSE_ENDPOINT = "pulses/subscribed"
  INDICATORS_ENDPOINT = "indicators"

  def handle
    response = fetch_recent_pulses
    puts normalize_pulse_data(response).to_json
  end
  # Constants

  # Configuration attributes
  class << self
    attr_accessor :api_key
  end

  def initialize(api_key = nil)
    @api_key = api_key || Rails.application.credentials.dig(:otx, :key)
    @http_client = create_http_client
  end

  # Fetch recent pulses (threat intelligence reports)
  def fetch_recent_pulses(limit = 20000)
    response = @http_client.get("#{PULSE_ENDPOINT}?limit=#{limit}")
    process_response(response)
  end

  # Search for pulses with specific keywords
  def search_pulses(query, limit = 20)
    response = @http_client.get("/search/pulses?q=#{URI.encode_www_form_component(query)}&limit=#{limit}")
    process_response(response)
  end

  # Get pulse by ID
  def get_pulse_by_id(pulse_id)
    response = @http_client.get("/pulses/#{pulse_id}")
    process_response(response)
  end

  # MITRE ATT&CK framework queries
  def get_pulses_by_attack_id(attack_id)
    response = @http_client.get("/pulses/attack_id/#{attack_id}")
    process_response(response)
  end

  # Normalize OTX pulse data to fit our unified schema
  def normalize_pulse_data(pulse_data)
    if pulse_data.key?("results")
      # Multiple pulses in results array
      pulses = pulse_data["results"] || []
    elsif pulse_data.key?("id")
      # Single pulse
      pulses = [ pulse_data ]
    else
      pulses = []
    end

    pulses.map do |pulse|
      {
        source: "otx",
        source_id: pulse["id"],
        title: pulse["name"],
        description: pulse["description"],
        created_at: pulse["created"],
        updated_at: pulse["modified"],
        tlp: pulse["tlp"] || "white",
        tags: pulse["tags"] || [],
        references: pulse["references"] || [],
        author: pulse["author_name"] || (pulse["author"] ? pulse["author"]["username"] : "Unknown"),
        confidence: calculate_confidence_score(pulse),
        malware_families: pulse["malware_families"] || [],
        attack_ids: pulse["attack_ids"] || [],
        industries: pulse["industries"] || [],
        targeted_countries: pulse["targeted_countries"] || [],
        adversary: pulse["adversary"],
        indicators: normalize_indicators(pulse["indicators"]),
        raw_data: pulse
      }
    end
  end

  def normalize_indicators(indicators)
    return [] unless indicators.is_a?(Array)

    indicators.map do |indicator|
      {
        source_id: indicator["id"],
        type: indicator["type"],
        value: indicator["indicator"],
        description: indicator["description"] || "",
        title: indicator["title"] || "",
        content: indicator["content"] || "",
        created_at: indicator["created"],
        role: indicator["role"] || "unknown",
        expiration: indicator["expiration"],
        is_active: indicator["is_active"] || true
      }
    end
  end

  # Fetch information about a specific IP
  def fetch_ip_details(ip_address)
    endpoint = "#{INDICATORS_ENDPOINT}/IPv4/#{ip_address}/general"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Fetch reputation data for a specific IP
  def fetch_ip_reputation(ip_address)
    endpoint = "#{INDICATORS_ENDPOINT}/IPv4/#{ip_address}/reputation"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Fetch passive DNS data for a specific IP
  def fetch_passive_dns(ip_address)
    endpoint = "#{INDICATORS_ENDPOINT}/IPv4/#{ip_address}/passive_dns"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Fetch malware samples related to a specific IP
  def fetch_ip_malware(ip_address)
    endpoint = "#{INDICATORS_ENDPOINT}/IPv4/#{ip_address}/malware"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Fetch information about a file hash
  def fetch_file_hash_details(hash_value, hash_type = nil)
    # Determine hash type if not provided
    unless hash_type
      hash_type = case hash_value.length
      when 32 then "FileHash-MD5"
      when 40 then "FileHash-SHA1"
      when 64 then "FileHash-SHA256"
      else "FileHash-Unknown"
      end
    end

    endpoint = "#{INDICATORS_ENDPOINT}/#{hash_type}/#{hash_value}/general"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Fetch information about a CVE
  def fetch_cve_details(cve_id)
    endpoint = "#{INDICATORS_ENDPOINT}/cve/#{cve_id}/general"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Fetch domain reputation
  def fetch_domain_reputation(domain)
    endpoint = "#{INDICATORS_ENDPOINT}/domain/#{domain}/reputation"
    response = @http_client.get(endpoint)
    process_response(response)
  end

  # Calculate a unified confidence score based on OTX pulse data
  def calculate_confidence_score(pulse)
    # Advanced algorithm that considers various pulse attributes
    base_score = 50

    # Adjust based on author
    if pulse["author_name"] == "AlienVault" || (pulse["author"] && pulse["author"]["username"] == "AlienVault")
      base_score += 15
    elsif pulse["author"] && pulse["author"]["is_subscribed"]
      base_score += 10
    end

    # Adjust based on references
    reference_count = pulse["references"]&.length || 0
    base_score += [ reference_count * 3, 15 ].min

    # Adjust based on indicators
    indicator_count = pulse["indicators"]&.length || 0
    base_score += [ indicator_count / 5, 20 ].min

    # Adjust based on MITRE ATT&CK framework references
    attack_ids_count = pulse["attack_ids"]&.length || 0
    base_score += [ attack_ids_count * 2, 10 ].min

    # Cap at 100
    [ base_score, 100 ].min
  end

  private

    def create_http_client
      Faraday.new(url: OTX_API_BASE_URL) do |faraday|
                faraday.request :json
                faraday.response :json
                # faraday.response :logger
                faraday.headers["X-OTX-API-KEY"] = @api_key
              end
      end

    def process_response(response)
      if response.status == 200
        response.body
      else
        Rails.logger.error("OTX API Error: #{response.status} - #{response.body}")
        raise "OTX API Error: #{response.status}"
      end
    end
end
