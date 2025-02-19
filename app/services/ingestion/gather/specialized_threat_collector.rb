class Ingestion::Gather::SpecializedThreatCollector
  def initialize(intel_collector)
    @intel_collector = intel_collector
    @logger = Logger.new('specialized_collection.log')
    @data_dir = 'threat_data/specialized/'
    FileUtils.mkdir_p(@data_dir)
  end

  # Collect OSINT (Open Source Intelligence) from Twitter/X
  def collect_twitter_osint(_api_key, _api_secret,
                            search_terms = ['cybersecurity', 'vulnerability', 'malware', 'infosec'])
    @logger.info("Collecting OSINT from Twitter for terms: #{search_terms.join(', ')}")

    # NOTE: Implementation will depend on Twitter API access
    # This is a placeholder structure
    osint_data = []

    search_terms.each do |term|
      # Placeholder for API call
      # Actual implementation would use proper Twitter API client
      @logger.info("Searching for term: #{term}")

      # Simulate data collection
      osint_data << {
        source: 'twitter',
        search_term: term,
        collection_time: Time.now.to_s,
        results: [],
      }
    end

    File.write("#{@data_dir}twitter_osint_#{Time.now.strftime('%Y%m%d')}.json", osint_data.to_json)
    @logger.info('Saved Twitter OSINT data')

    osint_data
  end

  # Collect CTI (Cyber Threat Intelligence) from specialized feeds
  def collect_cti_feeds
    @logger.info('Collecting specialized CTI feeds')

    cti_sources = [
      { name: 'Emerging Threats', url: 'https://rules.emergingthreats.net/open/suricata/rules/' },
      { name: 'Abuse.ch', url: 'https://feodotracker.abuse.ch/downloads/ipblocklist.csv' },
      { name: 'CI Army', url: 'https://cinsscore.com/list/ci-badguys.txt' },
      { name: 'AlienVault Reputation', url: 'https://reputation.alienvault.com/reputation.data' },
    ]

    cti_data = {}

    cti_sources.each do |source|
      @logger.info("Fetching CTI feed from #{source[:name]}")

      begin
        response = HTTParty.get(source[:url])

        if response.success?
          cti_data[source[:name]] = {
            source: source[:name],
            url: source[:url],
            collection_time: Time.now.to_s,
            raw_data: response.body,
            processed_data: process_cti_feed(source[:name], response.body),
          }

          @logger.info("Successfully collected CTI from #{source[:name]}")
        else
          @logger.error("Failed to collect CTI from #{source[:name]}: #{response.code}")
        end
      rescue StandardError => e
        @logger.error("Error collecting CTI from #{source[:name]}: #{e.message}")
      end
    end

    File.write("#{@data_dir}specialized_cti_#{Time.now.strftime('%Y%m%d')}.json", cti_data.to_json)
    @logger.info("Saved specialized CTI data from #{cti_data.keys.size} sources")

    cti_data
  end

  # Process CTI feed data into structured format
  def process_cti_feed(source_name, raw_data)
    case source_name
    when 'Emerging Threats'
      # Process Snort/Suricata rules
      process_ids_rules(raw_data)
    when 'Abuse.ch'
      # Process CSV format
      process_csv_blocklist(raw_data)
    when 'CI Army', 'AlienVault Reputation'
      # Process text-based IP lists
      process_ip_list(raw_data)
    else
      []
    end
  end

  # Process IDS rules (Snort/Suricata format)
  def process_ids_rules(raw_data)
    processed = []

    raw_data.lines.each do |line|
      # Skip comments and empty lines
      next if line.strip.empty? || line.start_with?('#')

      # Basic rule parsing
      next unless line.include?('alert') && line.include?('msg:')

      # Extract message
      msg_match = line.match(/msg:"([^"]+)"/)

      # Extract classification
      classtype_match = line.match(/classtype:([^;]+)/)

      # Extract IPs and ports
      ip_match = line.match(%r{\[([\d./,]+)\]})

      next unless msg_match

      processed << {
        rule_type: line.split(' ').first,
        message: msg_match[1],
        classification: classtype_match ? classtype_match[1].strip : 'unknown',
        ips: ip_match ? ip_match[1].split(',') : [],
        raw_rule: line.strip,
      }
    end

    processed
  end

  # Process CSV blocklist
  def process_csv_blocklist(raw_data)
    processed = []

    parser = CSV.new(raw_data)

    parser.each do |row|
      puts row
    end

    raw_data.lines.each do |line|
      # Skip comments and headers
      next if line.strip.empty? || line.start_with?('#')

      fields = line.strip.split(',')
      next if fields.size < 2

      processed << {
        ip: fields[0],
        status: fields[1],
        date: fields[2],
        additional_info: fields[3..-1],
      }
    end

    processed
  end

  # Process plain IP list
  def process_ip_list(raw_data)
    processed = []

    raw_data.lines.each do |line|
      line = line.strip
      # Skip comments and empty lines
      next if line.empty? || line.start_with?('#')

      # Check if line contains an IP
      ip_match = line.match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)

      next unless ip_match

      processed << {
        ip: ip_match[0],
        raw_line: line,
      }
    end

    processed
  end

  # Collect data from security mailing lists
  def collect_security_mailinglists
    @logger.info('Collecting security mailing list data')

    # Example feeds - actual implementation would use proper RSS/Atom parsing
    mailing_lists = [
      { name: 'Full Disclosure', url: 'https://seclists.org/rss/fulldisclosure.rss' },
      { name: 'Bugtraq', url: 'https://seclists.org/rss/bugtraq.rss' },
      { name: 'OSS Security', url: 'https://seclists.org/rss/oss-sec.rss' },
    ]

    ml_data = {}

    mailing_lists.each do |list|
      @logger.info("Fetching from #{list[:name]}")

      begin
        response = HTTParty.get(list[:url])

        if response.success?
          # Simple RSS parsing
          items = []
          rss_entries = response.body.scan(%r{<item>.*?</item>}m)

          rss_entries.each do |entry|
            title_match = entry.match(%r{<title>(.*?)</title>}m)
            link_match = entry.match(%r{<link>(.*?)</link>}m)
            date_match = entry.match(%r{<pubDate>(.*?)</pubDate>}m)

            next unless title_match && link_match

            items << {
              title: title_match[1],
              link: link_match[1],
              date: date_match ? date_match[1] : nil,
            }
          end

          ml_data[list[:name]] = {
            source: list[:name],
            url: list[:url],
            collection_time: Time.now.to_s,
            items: items,
          }

          @logger.info("Successfully collected #{items.size} items from #{list[:name]}")
        else
          @logger.error("Failed to collect from #{list[:name]}: #{response.code}")
        end
      rescue StandardError => e
        @logger.error("Error collecting from #{list[:name]}: #{e.message}")
      end
    end

    File.write("#{@data_dir}security_mailinglists_#{Time.now.strftime('%Y%m%d')}.json", ml_data.to_json)
    @logger.info('Saved security mailing list data')

    ml_data
  end

  # Combine specialized data with standard threat intel
  def prepare_specialized_features
    @logger.info('Preparing specialized features for model enhancement')

    # Load specialized data
    osint_data = begin
      JSON.parse(File.read("#{@data_dir}twitter_osint_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      []
    end
    cti_data = begin
      JSON.parse(File.read("#{@data_dir}specialized_cti_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      {}
    end
    ml_data = begin
      JSON.parse(File.read("#{@data_dir}security_mailinglists_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      {}
    end

    # Extract emerging threats
    emerging_threats = []
    keyword_frequencies = Hash.new(0)

    # Process OSINT data for keywords and trends
    osint_data.each do |osint|
      osint['results'].each do |result|
        # Extract keywords from text
        text = result['text'] || ''
        extract_keywords(text).each do |keyword|
          keyword_frequencies[keyword] += 1
        end
      end
    end

    # Process mailing list data
    ml_data.each do |list_name, list_data|
      list_data['items'].each do |item|
        # Extract emerging threats from security mailing list titles
        title = item['title'] || ''

        if title.match(/CVE-\d{4}-\d{4,}/) ||
           title.downcase.include?('vulnerability') ||
           title.downcase.include?('exploit')
          emerging_threats << {
            source: list_name,
            title: title,
            link: item['link'],
            date: item['date'],
            threat_type: categorize_threat(title),
          }
        end

        # Add to keyword frequencies
        extract_keywords(title).each do |keyword|
          keyword_frequencies[keyword] += 1
        end
      end
    end

    # Combine with existing threat intel
    specialized_features = {
      emerging_threats: emerging_threats,
      keyword_trends: keyword_frequencies.sort_by { |_k, v| -v }.take(100).to_h,
      threat_ips: extract_threat_ips(cti_data),
    }

    File.write("#{@data_dir}specialized_features_#{Time.now.strftime('%Y%m%d')}.json", specialized_features.to_json)
    @logger.info("Saved specialized features with #{emerging_threats.size} emerging threats and #{specialized_features[:threat_ips].size} threat IPs")

    specialized_features
  end

  # Extract keywords from text
  def extract_keywords(text)
    return [] unless text

    # Convert to lowercase and remove punctuation
    cleaned_text = text.downcase.gsub(/[^\w\s]/, ' ')

    # Split into words
    words = cleaned_text.split(/\s+/)

    # Filter out common words and keep security-relevant terms
    security_terms = ['vulnerability', 'exploit', 'malware', 'ransomware', 'backdoor', 'trojan', 'botnet', 'phishing',
                      'ddos', 'attack', 'breach', 'threat', 'security', 'patch', 'update', 'cve', 'disclosure',]

    words.select do |word|
      word.length > 3 &&
        !['the', 'and', 'that', 'this', 'with', 'for', 'from'].include?(word) &&
        (security_terms.include?(word) || word.match(/cve-\d{4}/))
    end
  end

  # Categorize threat type from title
  def categorize_threat(title)
    title_lower = title.downcase

    if title_lower.include?('remote code execution') || title_lower.include?('rce')
      'RCE'
    elsif title_lower.include?('dos') || title_lower.include?('denial of service')
      'DOS'
    elsif title_lower.include?('sql injection') || title_lower.include?('sqli')
      'SQL_INJECTION'
    elsif title_lower.include?('xss') || title_lower.include?('cross site')
      'XSS'
    elsif title_lower.include?('buffer overflow') || title_lower.include?('buffer over-read')
      'BUFFER_OVERFLOW'
    elsif title_lower.include?('privilege escalation') || title_lower.include?('priv esc')
      'PRIVILEGE_ESCALATION'
    elsif title_lower.include?('information disclosure') || title_lower.include?('data leak')
      'INFO_DISCLOSURE'
    elsif /cve-\d{4}-\d{4,}/.match?(title_lower)
      'CVE'
    else
      'GENERAL_VULNERABILITY'
    end
  end

  # Extract threat IPs from CTI data
  def extract_threat_ips(cti_data)
    threat_ips = []

    cti_data.each do |source, data|
      next unless data['processed_data'].is_a?(Array)

      data['processed_data'].each do |item|
        if item['ip']
          threat_ips << {
            ip: item['ip'],
            source: source,
            type: determine_threat_type(item, source),
          }
        elsif item['ips'] && item['ips'].is_a?(Array)
          item['ips'].each do |ip|
            threat_ips << {
              ip: ip,
              source: source,
              classification: item['classification'],
              message: item['message'],
            }
          end
        end
      end
    end

    threat_ips
  end

  # Determine threat type based on source and item data
  def determine_threat_type(item, source)
    case source
    when 'Abuse.ch'
      item['status'] || 'malware'
    when 'CI Army'
      'suspicious'
    when 'AlienVault Reputation'
      if item['raw_line'] && item['raw_line'].include?('#')
        item['raw_line'].split('#')[1].strip
      else
        'suspicious'
      end
    else
      'unknown'
    end
  end
end
