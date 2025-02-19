class Ingestion::Gather::ThreatIntelCollector
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
    @data_dir = 'threat_data/'
    FileUtils.mkdir_p(@data_dir)
  end

  # MISP data collection
  def collect_misp_data(api_key, base_url)
    @logger.info("Collecting MISP data from #{base_url}")

    headers = {
      'Authorization' => api_key,
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
    }

    # Get recent events
    response = HTTParty.get(
      "#{base_url}/events/index/sort:date/direction:desc/limit:1000",
      headers: headers,
    )

    if response.success?
      File.write("#{@data_dir}misp_events_#{Time.now.strftime('%Y%m%d')}.json", response.body)
      @logger.info("Successfully collected #{JSON.parse(response.body).size} MISP events")
      JSON.parse(response.body)
    else
      @logger.error("Failed to collect MISP data: #{response.code} - #{response.message}")
      []
    end
  end

  # AlienVault OTX data collection
  def collect_otx_data(api_key, pulse_days = 7)
    @logger.info("Collecting OTX pulses from the last #{pulse_days} days")

    headers = {
      'X-OTX-API-KEY' => api_key,
    }

    # Get recent pulses
    modified_since = (Time.now - (pulse_days * 86_400)).strftime('%Y-%m-%dT%H:%M:%S')
    response = HTTParty.get(
      "https://otx.alienvault.com/api/v1/pulses/subscribed?modified_since=#{modified_since}",
      headers: headers,
    )

    if response.success?
      data = JSON.parse(response.body)
      File.write("#{@data_dir}otx_pulses_#{Time.now.strftime('%Y%m%d')}.json", response.body)
      @logger.info("Successfully collected #{data['count']} OTX pulses")

      # Extract IOCs (Indicators of Compromise)
      iocs = extract_otx_iocs(data)
      File.write("#{@data_dir}otx_iocs_#{Time.now.strftime('%Y%m%d')}.json", iocs.to_json)

      data
    else
      @logger.error("Failed to collect OTX data: #{response.code} - #{response.message}")
      {}
    end
  end

  # Extract IOCs from OTX data
  def extract_otx_iocs(otx_data)
    iocs = {
      ip: [],
      domain: [],
      url: [],
      file_hash: [],
    }

    otx_data['results'].each do |pulse|
      pulse['indicators'].each do |indicator|
        case indicator['type']
        when 'IPv4', 'IPv6'
          iocs[:ip] << {
            value: indicator['indicator'],
            type: indicator['type'],
            created: indicator['created'],
            source: 'OTX',
            pulse_name: pulse['name'],
          }
        when 'domain', 'hostname'
          iocs[:domain] << {
            value: indicator['indicator'],
            type: indicator['type'],
            created: indicator['created'],
            source: 'OTX',
            pulse_name: pulse['name'],
          }
        when 'URL'
          iocs[:url] << {
            value: indicator['indicator'],
            type: indicator['type'],
            created: indicator['created'],
            source: 'OTX',
            pulse_name: pulse['name'],
          }
        when 'FileHash-MD5', 'FileHash-SHA1', 'FileHash-SHA256'
          iocs[:file_hash] << {
            value: indicator['indicator'],
            type: indicator['type'],
            created: indicator['created'],
            source: 'OTX',
            pulse_name: pulse['name'],
          }
        end
      end
    end

    iocs
  end

  # NVD Vulnerability data collection
  def collect_nvd_data(days_back = 120)
    @logger.info("Collecting NVD vulnerabilities from the last #{days_back} days")

    # Calculate start date

    end_date = (Time.now - days_back.days).strftime('%Y-%m-%dT00:00:00.000')
    start_date = Time.now.strftime('%Y-%m-%dT00:00:00.000')
    # Fetch recent CVEs
    response = HTTParty.get(
"https://services.nvd.nist.gov/rest/json/cves/2.0/?pubStartDate=#{end_date}&pubEndDate=#{start_date}",
)
    puts "https://services.nvd.nist.gov/rest/json/cves/2.0/?pubStartDate=#{end_date}&pubEndDate=#{start_date}"

    if response.success?
      data = JSON.parse(response.body)
      File.write("#{@data_dir}nvd_vulns_#{Time.now.strftime('%Y%m%d')}.json", data.to_json)
      @logger.info("Successfully collected #{data['totalResults']} vulnerabilities")

      # Process into structured format for model training
      processed_vulns = process_nvd_vulnerabilities(data)
      File.write("#{@data_dir}processed_vulns_#{Time.now.strftime('%Y%m%d')}.json", processed_vulns.to_json)

      data
    else
      @logger.error("Failed to collect NVD data: #{response.code} - #{response.message}")
      {}
    end
  end

  # Process NVD vulnerabilities into structured format
  def process_nvd_vulnerabilities(nvd_data)
    processed = []

    nvd_data['vulnerabilities'].each do |vuln|
      cve = vuln['cve']

      # Extract CVSS score
      base_score = nil
      base_severity = nil

      if cve['metrics'] && cve['metrics']['cvssMetricV31']
        metrics = cve['metrics']['cvssMetricV31'][0]['cvssData']
        base_score = metrics['baseScore']
        base_severity = metrics['baseSeverity']
      elsif cve['metrics'] && cve['metrics']['cvssMetricV30']
        metrics = cve['metrics']['cvssMetricV30'][0]['cvssData']
        base_score = metrics['baseScore']
        base_severity = metrics['baseSeverity']
      elsif cve['metrics'] && cve['metrics']['cvssMetricV2']
        metrics = cve['metrics']['cvssMetricV2'][0]['cvssData']
        base_score = metrics['baseScore']
        base_severity = metrics['baseSeverity']
      end

      # Extract CWE (weakness type)
      cwes = []
      if cve['weaknesses']
        cve['weaknesses'].each do |weakness|
          weakness['description'].each do |desc|
            cwes << desc['value'] if desc['value'].start_with?('CWE-')
          end
        end
      end

      processed << {
        cve_id: cve['id'],
        published: cve['published'],
        last_modified: cve['lastModified'],
        description: cve['descriptions'][0]['value'],
        cvss_score: base_score,
        severity: base_severity,
        cwe: cwes,
        references: cve['references'].map { |ref| ref['url'] },
      }
    end

    processed
  end

  # Parse firewall logs from common formats
  def parse_firewall_logs(log_file, format = 'cisco')
    @logger.info("Parsing firewall logs from #{log_file}")

    logs = []
    begin
      File.foreach(log_file) do |line|
        case format
        when 'cisco'
          # Example parsing for Cisco ASA logs
          if line.include?('%ASA-')
            parts = line.split('%ASA-')[1].split(':')
            severity = parts[0]
            message = parts[1].strip

            # Extract timestamp, IPs, ports, etc.
            timestamp_match = line.match(/([A-Z][a-z]{2}\s+\d+\s+\d{2}:\d{2}:\d{2})/)
            src_ip_match = message.match(/src\s+(\d+\.\d+\.\d+\.\d+)/)
            dst_ip_match = message.match(/dst\s+(\d+\.\d+\.\d+\.\d+)/)

            logs << {
              timestamp: timestamp_match ? timestamp_match[1] : nil,
              severity: severity,
              source_ip: src_ip_match ? src_ip_match[1] : nil,
              destination_ip: dst_ip_match ? dst_ip_match[1] : nil,
              raw_message: message,
            }
          end
        when 'pfsense'
          # Example parsing for pfSense logs
          # Add implementation
        when 'fortinet'
          # Example parsing for Fortinet logs
          # Add implementation
        end
      end

      @logger.info("Successfully parsed #{logs.size} log entries")
      File.write("#{@data_dir}parsed_fw_logs_#{Time.now.strftime('%Y%m%d')}.json", logs.to_json)
      logs
    rescue StandardError => e
      @logger.error("Error parsing firewall logs: #{e.message}")
      []
    end
  end

  # Extract features for time series models
  def prepare_time_series_features(logs, interval = 'hourly')
    @logger.info("Preparing time series features with #{interval} interval")

    # Group logs by time interval
    grouped_data = {}

    logs.each do |log|
      next unless log[:timestamp]

      begin
        time_obj = Time.parse(log[:timestamp])

        # Create interval key based on specified granularity
        key = case interval
              when 'hourly'
                time_obj.strftime('%Y-%m-%d %H:00:00')
              when 'daily'
                time_obj.strftime('%Y-%m-%d 00:00:00')
              when '15min'
                minutes = (time_obj.min / 15) * 15
                time_obj.strftime("%Y-%m-%d %H:#{minutes}:00")
              end

        grouped_data[key] ||= {
          count: 0,
          source_ips: Set.new,
          destination_ips: Set.new,
          severities: Hash.new(0),
        }

        grouped_data[key][:count] += 1
        grouped_data[key][:source_ips].add(log[:source_ip]) if log[:source_ip]
        grouped_data[key][:destination_ips].add(log[:destination_ip]) if log[:destination_ip]
        grouped_data[key][:severities][log[:severity]] += 1 if log[:severity]
      rescue StandardError => e
        @logger.warn("Could not parse timestamp: #{log[:timestamp]} - #{e.message}")
      end
    end

    # Convert to array of feature vectors
    time_series_data = []
    grouped_data.each do |timestamp, data|
      # Calculate entropy of source IPs
      src_ip_entropy = calculate_entropy(data[:source_ips].size, logs.size)
      dst_ip_entropy = calculate_entropy(data[:destination_ips].size, logs.size)

      # Calculate average severity
      severity_sum = 0
      severity_count = 0
      data[:severities].each do |sev, count|
        severity_value = sev.to_i
        severity_sum += (severity_value * count)
        severity_count += count
      end
      avg_severity = severity_count > 0 ? (severity_sum.to_f / severity_count) : 0

      time_series_data << {
        timestamp: timestamp,
        attack_count: data[:count],
        severity_score: avg_severity,
        source_ip_entropy: src_ip_entropy,
        target_ip_entropy: dst_ip_entropy,
        unique_source_ips: data[:source_ips].size,
        unique_destination_ips: data[:destination_ips].size,
      }
    end

    # Sort by timestamp
    time_series_data.sort_by! { |x| x[:timestamp] }

    File.write("#{@data_dir}time_series_features_#{interval}_#{Time.now.strftime('%Y%m%d')}.json",
      time_series_data.to_json,)
    @logger.info("Generated #{time_series_data.size} time series data points")

    time_series_data
  end

  # Helper function to calculate entropy
  def calculate_entropy(unique_items, total_items)
    return 0 if unique_items == 0 || total_items == 0

    probability = unique_items.to_f / total_items
    -probability * Math.log2(probability)
  end

  # Prepare features for the classification models
  def prepare_classification_features(logs)
    @logger.info('Preparing classification features')

    classification_data = []

    logs.each do |log|
      # Skip logs with insufficient data
      next unless log[:source_ip] && log[:destination_ip]

      # Extract features from the log entry
      features = {
        timestamp: log[:timestamp],
        source_ip: log[:source_ip],
        destination_ip: log[:destination_ip],
        port_numbers: extract_ports(log[:raw_message]),
        protocol_type: extract_protocol(log[:raw_message]),
        packet_size: extract_packet_size(log[:raw_message]),
        connection_duration: extract_duration(log[:raw_message]),
        bytes_transferred: extract_bytes(log[:raw_message]),
        flag_bits: extract_flags(log[:raw_message]),
      }

      # Label the data if possible (might require manual labeling or heuristics)
      features[:attack_type] = categorize_attack(log[:raw_message])

      classification_data << features
    end

    File.write("#{@data_dir}classification_features_#{Time.now.strftime('%Y%m%d')}.json", classification_data.to_json)
    @logger.info("Generated #{classification_data.size} classification feature vectors")

    classification_data
  end

  # Helper methods for feature extraction
  def extract_ports(message)
    return [] unless message

    # Extract source and destination ports
    ports = []
    src_port_match = message.match(/sport\s+(\d+)/)
    dst_port_match = message.match(/dport\s+(\d+)/)

    ports << src_port_match[1].to_i if src_port_match
    ports << dst_port_match[1].to_i if dst_port_match

    ports
  end

  def extract_protocol(message)
    return nil unless message

    if message.include?('TCP')
      'TCP'
    elsif message.include?('UDP')
      'UDP'
    elsif message.include?('ICMP')
      'ICMP'
    else
      'UNKNOWN'
    end
  end

  def extract_packet_size(message)
    return nil unless message

    size_match = message.match(/length\s+(\d+)/)
    size_match ? size_match[1].to_i : nil
  end

  def extract_duration(message)
    return nil unless message

    duration_match = message.match(/duration\s+([\d.]+)\s+sec/)
    duration_match ? duration_match[1].to_f : nil
  end

  def extract_bytes(message)
    return nil unless message

    bytes_match = message.match(/bytes\s+(\d+)/)
    bytes_match ? bytes_match[1].to_i : nil
  end

  def extract_flags(message)
    return [] unless message

    flags = []
    flags << 'SYN' if message.include?('SYN')
    flags << 'ACK' if message.include?('ACK')
    flags << 'FIN' if message.include?('FIN')
    flags << 'RST' if message.include?('RST')
    flags << 'PUSH' if message.include?('PUSH') || message.include?('PSH')
    flags << 'URG' if message.include?('URG')

    flags
  end

  def categorize_attack(message)
    return 'UNKNOWN' unless message

    if message.include?('port scan') || message.include?('scan detected')
      'RECONNAISSANCE'
    elsif message.include?('brute force') || message.include?('authentication failure')
      'BRUTE_FORCE'
    elsif message.include?('DDoS') || message.include?('flood')
      'DDOS'
    elsif message.include?('SQL injection') || message.include?('XSS')
      'WEB_ATTACK'
    elsif message.include?('malware') || message.include?('virus')
      'MALWARE'
    elsif message.include?('backdoor') || message.include?('C&C')
      'BACKDOOR'
    else
      'UNKNOWN'
    end
  end

  # Collect training data from honeypots
  def collect_honeypot_data(honeypot_logs_dir)
    @logger.info("Collecting honeypot data from #{honeypot_logs_dir}")

    honeypot_data = []

    Dir.glob("#{honeypot_logs_dir}/*.log").each do |log_file|
      File.foreach(log_file) do |line|
        data = begin
          JSON.parse(line)
        rescue StandardError
          next
        end

        # Structure depends on honeypot type (Cowrie, Dionaea, etc.)
        honeypot_data << {
          timestamp: data['timestamp'] || data['time'] || Time.now.to_s,
          source_ip: data['src_ip'] || data['source_ip'] || data['remote_ip'] || data['ip'],
          destination_ip: data['dest_ip'] || data['destination_ip'] || data['local_ip'],
          source_port: data['src_port'] || data['source_port'],
          destination_port: data['dest_port'] || data['destination_port'] || data['port'],
          protocol: data['protocol'],
          attack_type: data['attack_type'] || 'UNKNOWN',
          payload: data['payload'],
          user_agent: data['user_agent'],
          commands: data['commands'],
          raw_data: data,
        }
      end
    rescue StandardError => e
      @logger.error("Error processing honeypot log #{log_file}: #{e.message}")
    end

    File.write("#{@data_dir}honeypot_data_#{Time.now.strftime('%Y%m%d')}.json", honeypot_data.to_json)
    @logger.info("Collected #{honeypot_data.size} honeypot events")

    honeypot_data
  end

  # Prepare a combined dataset for model training
  def prepare_combined_dataset
    @logger.info('Preparing combined dataset for model training')

    # Load previously collected data
    time_series_data = begin
      JSON.parse(File.read("#{@data_dir}time_series_features_hourly_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      []
    end
    classification_data = begin
      JSON.parse(File.read("#{@data_dir}classification_features_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      []
    end
    vulnerability_data = begin
      JSON.parse(File.read("#{@data_dir}processed_vulns_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      []
    end
    honeypot_data = begin
      JSON.parse(File.read("#{@data_dir}honeypot_data_#{Time.now.strftime('%Y%m%d')}.json"))
    rescue StandardError
      []
    end

    # Create specialized datasets for each model type
    prepare_prophet_dataset(time_series_data)
    prepare_xgboost_dataset(classification_data, honeypot_data)
    prepare_isolation_forest_dataset(classification_data, honeypot_data)
    prepare_lstm_dataset(classification_data, honeypot_data, time_series_data)
    prepare_gnn_dataset(classification_data, honeypot_data, vulnerability_data)

    @logger.info('Successfully prepared all datasets for model training')
  end

  # Prepare dataset for Prophet time series model
  def prepare_prophet_dataset(time_series_data)
    @logger.info('Preparing Prophet dataset')

    prophet_data = []

    time_series_data.each do |data_point|
      prophet_data << {
        ds: data_point['timestamp'],
        y: data_point['attack_count'],
        severity: data_point['severity_score'],
        src_entropy: data_point['source_ip_entropy'],
        dst_entropy: data_point['target_ip_entropy'],
      }
    end

    # Save as CSV (Prophet preferred format)
    CSV.open("#{@data_dir}prophet_dataset_#{Time.now.strftime('%Y%m%d')}.csv", 'w') do |csv|
      csv << ['ds', 'y', 'severity', 'src_entropy', 'dst_entropy']
      prophet_data.each do |row|
        csv << [row[:ds], row[:y], row[:severity], row[:src_entropy], row[:dst_entropy]]
      end
    end

    @logger.info("Saved Prophet dataset with #{prophet_data.size} rows")
  end

  # Prepare dataset for XGBoost classification model
  def prepare_xgboost_dataset(classification_data, honeypot_data)
    @logger.info('Preparing XGBoost classification dataset')

    # Combine labeled data from classification and honeypot sources
    combined_data = []

    # Process classification data
    classification_data.each do |data_point|
      next unless data_point['attack_type'] && data_point['attack_type'] != 'UNKNOWN'

      features = {
        port_numbers: data_point['port_numbers'],
        protocol_type: encode_protocol(data_point['protocol_type']),
        packet_size: data_point['packet_size'],
        connection_duration: data_point['connection_duration'],
        bytes_transferred: data_point['bytes_transferred'],
        has_syn: data_point['flag_bits']&.include?('SYN') ? 1 : 0,
        has_ack: data_point['flag_bits']&.include?('ACK') ? 1 : 0,
        has_fin: data_point['flag_bits']&.include?('FIN') ? 1 : 0,
        has_rst: data_point['flag_bits']&.include?('RST') ? 1 : 0,
        has_push: data_point['flag_bits']&.include?('PUSH') ? 1 : 0,
        has_urg: data_point['flag_bits']&.include?('URG') ? 1 : 0,
        label: data_point['attack_type'],
      }

      combined_data << features
    end

    # Process honeypot data
    honeypot_data.each do |data_point|
      next unless data_point['attack_type'] && data_point['attack_type'] != 'UNKNOWN'

      features = {
        port_numbers: [data_point['source_port'].to_i, data_point['destination_port'].to_i],
        protocol_type: encode_protocol(data_point['protocol']),
        packet_size: nil, # Might not be available in honeypot data
        connection_duration: nil,
        bytes_transferred: nil,
        has_syn: 0,
        has_ack: 0,
        has_fin: 0,
        has_rst: 0,
        has_push: 0,
        has_urg: 0,
        label: data_point['attack_type'],
      }

      combined_data << features
    end

    # Handle missing values
    combined_data.each do |row|
      row[:packet_size] ||= 0
      row[:connection_duration] ||= 0
      row[:bytes_transferred] ||= 0
      row[:port_numbers] = [0, 0] if row[:port_numbers].nil? || row[:port_numbers].empty?
    end

    # Save as CSV
    CSV.open("#{@data_dir}xgboost_dataset_#{Time.now.strftime('%Y%m%d')}.csv", 'w') do |csv|
      csv << ['port1', 'port2', 'protocol', 'packet_size', 'duration', 'bytes', 'syn', 'ack', 'fin', 'rst', 'push',
              'urg', 'label',]

      combined_data.each do |row|
        csv << [
          row[:port_numbers][0] || 0,
          row[:port_numbers][1] || 0,
          row[:protocol_type],
          row[:packet_size],
          row[:connection_duration],
          row[:bytes_transferred],
          row[:has_syn],
          row[:has_ack],
          row[:has_fin],
          row[:has_rst],
          row[:has_push],
          row[:has_urg],
          row[:label],
        ]
      end
    end

    @logger.info("Saved XGBoost dataset with #{combined_data.size} rows")
  end

  # Helper to encode protocol as numeric
  def encode_protocol(protocol)
    case protocol
    when 'TCP'
      1
    when 'UDP'
      2
    when 'ICMP'
      3
    else
      0
    end
  end

  # Prepare dataset for Isolation Forest anomaly detection
  def prepare_isolation_forest_dataset(classification_data, honeypot_data)
    @logger.info('Preparing Isolation Forest dataset')

    # Extract features for anomaly detection
    anomaly_features = []

    # Process normal network traffic data
    classification_data.each do |data_point|
      next unless data_point['source_ip'] && data_point['destination_ip']

      features = {
        source_ip: data_point['source_ip'],
        destination_ip: data_point['destination_ip'],
        port_count: data_point['port_numbers']&.size || 0,
        protocol: encode_protocol(data_point['protocol_type']),
        packet_size: data_point['packet_size'],
        duration: data_point['connection_duration'],
        bytes: data_point['bytes_transferred'],
        flag_count: data_point['flag_bits']&.size || 0,
        is_known_attack: data_point['attack_type'] == 'UNKNOWN' ? 0 : 1,
      }

      anomaly_features << features
    end

    # Process honeypot data (known attacks)
    honeypot_data.each do |data_point|
      features = {
        source_ip: data_point['source_ip'],
        destination_ip: data_point['destination_ip'],
        port_count: 2, # Source and destination port
        protocol: encode_protocol(data_point['protocol']),
        packet_size: 0,
        duration: 0,
        bytes: 0,
        flag_count: 0,
        is_known_attack: 1,
      }

      anomaly_features << features
    end

    # Convert IP addresses to numeric features
    anomaly_features.each do |row|
      row[:src_ip_numeric] = ip_to_numeric(row[:source_ip])
      row[:dst_ip_numeric] = ip_to_numeric(row[:destination_ip])
      row.delete(:source_ip)
      row.delete(:destination_ip)
    end

    # Save as CSV
    CSV.open("#{@data_dir}isolation_forest_dataset_#{Time.now.strftime('%Y%m%d')}.csv", 'w') do |csv|
      csv << ['src_ip_numeric', 'dst_ip_numeric', 'port_count', 'protocol', 'packet_size', 'duration', 'bytes',
              'flag_count', 'is_known_attack',]

      anomaly_features.each do |row|
        csv << [
          row[:src_ip_numeric],
          row[:dst_ip_numeric],
          row[:port_count],
          row[:protocol],
          row[:packet_size],
          row[:duration],
          row[:bytes],
          row[:flag_count],
          row[:is_known_attack],
        ]
      end
    end

    @logger.info("Saved Isolation Forest dataset with #{anomaly_features.size} rows")
  end

  # Helper to convert IP to numeric value
  def ip_to_numeric(ip)
    return 0 unless ip

    # Handle IPv4
    if ip.count('.') == 3
      parts = ip.split('.')
      return (parts[0].to_i * (256**3)) + (parts[1].to_i * (256**2)) + (parts[2].to_i * 256) + parts[3].to_i
    end

    # Simple hash for IPv6 or invalid IPs
    ip.bytes.sum
  end

  # Prepare dataset for LSTM sequence prediction
  # Continue preparing LSTM dataset
  def prepare_lstm_dataset(classification_data, honeypot_data, _time_series_data)
    @logger.info('Preparing LSTM sequence dataset')

    # Group attacks by source IP to create sequences
    attack_sequences = {}

    # Add classification data
    classification_data.each do |data_point|
      next unless data_point['source_ip'] && data_point['attack_type'] && data_point['attack_type'] != 'UNKNOWN'

      source_ip = data_point['source_ip']
      attack_sequences[source_ip] ||= []

      attack_sequences[source_ip] << {
        timestamp: Time.parse(data_point['timestamp'].to_s),
        attack_type: data_point['attack_type'],
        target_ip: data_point['destination_ip'],
        port: data_point['port_numbers']&.last,
      }
    end

    # Add honeypot data
    honeypot_data.each do |data_point|
      next unless data_point['source_ip']

      source_ip = data_point['source_ip']
      attack_sequences[source_ip] ||= []

      attack_sequences[source_ip] << {
        timestamp: Time.parse(data_point['timestamp'].to_s),
        attack_type: data_point['attack_type'] || 'UNKNOWN',
        target_ip: data_point['destination_ip'],
        port: data_point['destination_port'],
      }
    end

    # Sort sequences by timestamp
    attack_sequences.each do |ip, sequence|
      attack_sequences[ip] = sequence.sort_by { |a| a[:timestamp] }
    end

    # Generate sequence data for LSTM
    sequence_data = []

    # Only use sequences with at least 3 events
    attack_sequences.each do |_ip, events|
      next if events.size < 3

      # Create sliding windows of events
      (0..(events.size - 3)).each do |i|
        window = events[i..(i + 2)]

        # Encode attack types
        attack_types = window.map { |e| encode_attack_type(e[:attack_type]) }

        # Calculate time deltas between events (in seconds)
        time_deltas = []
        (1...window.size).each do |j|
          time_deltas << (window[j][:timestamp] - window[j - 1][:timestamp]).to_i
        end

        # Encode target similarity (1 if same target IP, 0 if different)
        target_similarity = window[0][:target_ip] == window[1][:target_ip] ? 1 : 0

        # Prepare sequence and label
        input_sequence = attack_types[0..1] + time_deltas + [target_similarity]
        output_label = attack_types[2]

        sequence_data << {
          input: input_sequence,
          output: output_label,
        }
      end
    end

    # Save as JSON
    File.write("#{@data_dir}lstm_sequence_data_#{Time.now.strftime('%Y%m%d')}.json", sequence_data.to_json)
    @logger.info("Saved LSTM dataset with #{sequence_data.size} sequences")

    sequence_data
  end

  # Helper to encode attack type as numeric
  def encode_attack_type(attack_type)
    attack_codes = {
      'RECONNAISSANCE' => 1,
      'BRUTE_FORCE' => 2,
      'DDOS' => 3,
      'WEB_ATTACK' => 4,
      'MALWARE' => 5,
      'BACKDOOR' => 6,
      'UNKNOWN' => 0,
    }

    attack_codes[attack_type] || 0
  end

  # Prepare dataset for Graph Neural Networks
  def prepare_gnn_dataset(classification_data, _honeypot_data, vulnerability_data)
    @logger.info('Preparing GNN dataset')

    # Create nodes (IPs, ports, attack types)
    nodes = {
      ip: [],
      port: [],
      attack_type: [],
      vulnerability: [],
    }

    # Create edges (connections between nodes)
    edges = []

    # Process classification data
    ip_set = Set.new
    port_set = Set.new
    attack_type_set = Set.new

    classification_data.each do |data_point|
      next unless data_point['source_ip'] && data_point['destination_ip']

      # Add IPs as nodes
      source_ip = data_point['source_ip']
      destination_ip = data_point['destination_ip']

      unless ip_set.include?(source_ip)
        ip_set.add(source_ip)
        nodes[:ip] << {
          id: "ip-#{source_ip}",
          type: 'ip',
          address: source_ip,
          role: 'source',
        }
      end

      unless ip_set.include?(destination_ip)
        ip_set.add(destination_ip)
        nodes[:ip] << {
          id: "ip-#{destination_ip}",
          type: 'ip',
          address: destination_ip,
          role: 'target',
        }
      end

      # Add ports as nodes
      if data_point['port_numbers']
        data_point['port_numbers'].each do |port|
          port_key = "#{port}"
          unless port_set.include?(port_key)
            port_set.add(port_key)
            nodes[:port] << {
              id: "port-#{port}",
              type: 'port',
              number: port,
            }
          end

          # Create edge between IP and port
          edges << {
            source: "ip-#{destination_ip}",
            target: "port-#{port}",
            relationship: 'has_port',
            weight: 1.0,
          }
        end
      end

      # Add attack type as node
      if data_point['attack_type'] && data_point['attack_type'] != 'UNKNOWN'
        attack_type = data_point['attack_type']
        unless attack_type_set.include?(attack_type)
          attack_type_set.add(attack_type)
          nodes[:attack_type] << {
            id: "attack-#{attack_type}",
            type: 'attack_type',
            name: attack_type,
          }
        end

        # Create edge between source IP and attack type
        edges << {
          source: "ip-#{source_ip}",
          target: "attack-#{attack_type}",
          relationship: 'performs',
          weight: 1.0,
        }
      end

      # Create edge between source and destination
      edges << {
        source: "ip-#{source_ip}",
        target: "ip-#{destination_ip}",
        relationship: 'connects_to',
        weight: 1.0,
        timestamp: data_point['timestamp'],
      }
    end

    # Process vulnerability data
    vulnerability_set = Set.new

    vulnerability_data.each do |vuln|
      cve_id = vuln['cve_id']
      next if vulnerability_set.include?(cve_id)

      vulnerability_set.add(cve_id)
      nodes[:vulnerability] << {
        id: "vuln-#{cve_id}",
        type: 'vulnerability',
        cve_id: cve_id,
        severity: vuln['cvss_score'],
      }
    end

    # Save as JSON for graph data
    graph_data = {
      nodes: {
        ip: nodes[:ip],
        port: nodes[:port],
        attack_type: nodes[:attack_type],
        vulnerability: nodes[:vulnerability],
      },
      edges: edges,
    }

    File.write("#{@data_dir}gnn_graph_data_#{Time.now.strftime('%Y%m%d')}.json", graph_data.to_json)
    @logger.info("Saved GNN dataset with #{nodes[:ip].size} IP nodes, #{nodes[:port].size} port nodes, " +
                "#{nodes[:attack_type].size} attack type nodes, #{nodes[:vulnerability].size} vulnerability nodes, " +
                "and #{edges.size} edges")

    graph_data
  end
end
