class Ingestion::Extended::ThreatIntelCollector
  def initialize(storage_path = './threat_data')
    @storage_path = storage_path
    FileUtils.mkdir_p(storage_path)
    # Initialize Elasticsearch for storage if needed
    @es = Elasticsearch::Client.new(url: 'http://localhost:9200')
  end

  def collect_mitre_attack
    puts 'Collecting MITRE ATT&CK data...'

    # Enterprise ATT&CK
    uri = URI('https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json')
    response = Net::HTTP.get(uri)
    attack_data = JSON.parse(response)

    # Extract techniques and their relationships
    techniques = []
    relationships = []

    attack_data['objects'].each do |obj|
      if obj['type'] == 'attack-pattern'
        technique = {
          'id' => obj['id'],
          'name' => obj['name'],
          'description' => obj['description'] || '',
          'tactics' => (obj['kill_chain_phases'] || []).map { |phase| phase['phase_name'] },
        }
        techniques << technique
      elsif obj['type'] == 'relationship'
        relationship = {
          'source_ref' => obj['source_ref'],
          'target_ref' => obj['target_ref'],
          'relationship_type' => obj['relationship_type'],
        }
        relationships << relationship
      end
    end

    # Save to files
    save_to_csv(techniques, "#{@storage_path}/mitre_techniques.csv")
    save_to_csv(relationships, "#{@storage_path}/mitre_relationships.csv")

    # Index in Elasticsearch for graph analysis
    techniques.each do |technique|
      @es.index(index: 'mitre-techniques', id: technique['id'], body: technique)
    end

    [techniques.length, relationships.length]
  end

  def collect_alienvault_otx(api_key, days_back = 30)
    puts 'Collecting AlienVault OTX data...'

    headers = { 'X-OTX-API-KEY' => api_key }
    modified_since = (Date.today - days_back).iso8601

    # Get recent pulses
    uri = URI('https://otx.alienvault.com/api/v1/pulses/subscribed')
    uri.query = URI.encode_www_form({ 'modified_since' => modified_since })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri, headers)
    response = http.request(request)

    pulses = JSON.parse(response.body)['results']

    all_indicators = []
    pulses.each do |pulse|
      pulse_id = pulse['id']
      pulse_name = pulse['name']
      pulse_tags = pulse['tags']

      # Get indicators for each pulse
      indicator_uri = URI("https://otx.alienvault.com/api/v1/pulses/#{pulse_id}/indicators")
      indicator_request = Net::HTTP::Get.new(indicator_uri.request_uri, headers)
      indicator_response = http.request(indicator_request)
      indicators = JSON.parse(indicator_response.body)['results']

      indicators.each do |indicator|
        indicator['pulse_id'] = pulse_id
        indicator['pulse_name'] = pulse_name
        indicator['pulse_tags'] = pulse_tags
        all_indicators << indicator
      end
    end

    # Save to file
    save_to_csv(all_indicators, "#{@storage_path}/alienvault_indicators.csv")

    # Create time series data for volume prediction
    daily_counts = {}
    all_indicators.each do |indicator|
      date = Date.parse(indicator['created']).to_s
      type = indicator['type']

      daily_counts[date] ||= {}
      daily_counts[date][type] ||= 0
      daily_counts[date][type] += 1
    end

    # Save daily counts
    daily_counts_rows = []
    daily_counts.each do |date, type_counts|
      row = { 'date' => date }
      type_counts.each do |type, count|
        row[type] = count
      end
      daily_counts_rows << row
    end

    save_to_csv(daily_counts_rows, "#{@storage_path}/alienvault_daily_indicator_counts.csv")

    [pulses.length, all_indicators.length]
  end

  def collect_abuse_ch_urlhaus
    puts 'Collecting URLhaus data...'

    uri = URI('https://urlhaus.abuse.ch/downloads/csv/')
    response = Net::HTTP.get(uri)

    # Skip comment lines
    lines = response.split("\n")
    data_lines = lines.reject { |line| line.start_with?('#') || line.empty? }

    # Create CSV header
    header = ['id', 'dateadded', 'url', 'url_status', 'threat', 'tags', 'urlhaus_link', 'reporter']

    # Save to file
    File.open("#{@storage_path}/urlhaus_urls.csv", 'w') do |f|
      f.puts header.join(',')
      data_lines.each { |line| f.puts line }
    end

    # Parse for time series analysis
    begin
      # Read CSV
      csv_data = CSV.read("#{@storage_path}/urlhaus_urls.csv", headers: true)

      # Group by date and threat
      daily_counts = {}
      csv_data.each do |row|
        date = Date.parse(row['dateadded']).to_s
        threat = row['threat']

        daily_counts[date] ||= {}
        daily_counts[date][threat] ||= 0
        daily_counts[date][threat] += 1
      rescue StandardError
        # Skip rows with invalid dates
        next
      end

      # Save daily threat counts
      daily_threats = []
      daily_counts.each do |date, threat_counts|
        row = { 'date' => date }
        threat_counts.each do |threat, count|
          row[threat] = count
        end
        daily_threats << row
      end

      save_to_csv(daily_threats, "#{@storage_path}/urlhaus_daily_threat_counts.csv")
    rescue StandardError => e
      puts "Error creating time series data: #{e}"
    end

    data_lines.length
  end

  def collect_nvd_vulnerabilities(days_back = 30)
    puts 'Collecting NVD vulnerability data...'

    # Calculate date range
    end_date = Date.today
    start_date = end_date - days_back

    # Format dates for API
    start_str = "#{start_date.strftime('%Y-%m-%d')}T00:00:00:000 UTC-00:00"
    end_str = "#{end_date.strftime('%Y-%m-%d')}T23:59:59:999 UTC-00:00"

    # Fetch vulnerabilities
    uri = URI('https://services.nvd.nist.gov/rest/json/cves/2.0')
    uri.query = URI.encode_www_form({
      'pubStartDate' => start_str,
      'pubEndDate' => end_str,
      'resultsPerPage' => 2000,
    })

    response = Net::HTTP.get(uri)
    nvd_data = JSON.parse(response)

    # Extract relevant details
    vulnerabilities = []
    nvd_data.fetch('vulnerabilities', []).each do |vuln|
      cve_item = vuln['cve']

      # Get CVSS scores if available
      cvss_v3 = nil
      cvss_v2 = nil

      metrics = cve_item.fetch('metrics', {})
      if metrics['cvssMetricV31']
        cvss_v3 = metrics['cvssMetricV31'][0]['cvssData']['baseScore']
      elsif metrics['cvssMetricV30']
        cvss_v3 = metrics['cvssMetricV30'][0]['cvssData']['baseScore']
      end

      cvss_v2 = metrics['cvssMetricV2'][0]['cvssData']['baseScore'] if metrics['cvssMetricV2']

      # Extract CWE if available
      cwes = []
      cve_item.fetch('weaknesses', []).each do |weakness|
        weakness.fetch('description', []).each do |desc|
          cwes << desc.fetch('value', '') if desc.fetch('lang') == 'en'
        end
      end

      vuln_data = {
        'id' => cve_item['id'],
        'published' => cve_item['published'],
        'lastModified' => cve_item['lastModified'],
        'description' => cve_item.fetch('descriptions', [{}])[0]['value'],
        'cvss_v3' => cvss_v3,
        'cvss_v2' => cvss_v2,
        'cwes' => cwes.join(','),
      }

      vulnerabilities << vuln_data
    end

    # Save to file
    save_to_csv(vulnerabilities, "#{@storage_path}/nvd_vulnerabilities.csv")

    # Create time series features
    daily_counts = {}
    daily_severity = {}

    vulnerabilities.each do |vuln|
      date = Date.parse(vuln['published']).to_s
      severity = vuln['cvss_v3'].to_f

      daily_counts[date] ||= 0
      daily_counts[date] += 1

      daily_severity[date] ||= []
      daily_severity[date] << severity if severity > 0
    end

    # Calculate average severity
    avg_severity = {}
    daily_severity.each do |date, scores|
      avg_severity[date] = scores.empty? ? 0 : scores.sum / scores.length
    end

    # Save time series data
    time_series_rows = []
    daily_counts.keys.each do |date|
      time_series_rows << {
        'date' => date,
        'count' => daily_counts[date],
        'avg_severity' => avg_severity[date] || 0,
      }
    end

    save_to_csv(time_series_rows, "#{@storage_path}/nvd_daily_stats.csv")

    vulnerabilities.length
  end

  def prepare_time_series_data
    puts 'Preparing time series data...'

    begin
      # Load daily counts from different sources
      otx_counts = load_csv("#{@storage_path}/alienvault_daily_indicator_counts.csv")
      urlhaus_counts = load_csv("#{@storage_path}/urlhaus_daily_threat_counts.csv")
      nvd_stats = load_csv("#{@storage_path}/nvd_daily_stats.csv")

      # Get all unique dates
      all_dates = Set.new

      otx_counts.each { |row| all_dates << row['date'] }
      urlhaus_counts.each { |row| all_dates << row['date'] }
      nvd_stats.each { |row| all_dates << row['date'] }

      all_dates = all_dates.to_a.sort

      # Create comprehensive time series dataframe
      ts_data = []

      all_dates.each do |date|
        row = { 'date' => date }

        # Add OTX indicator counts
        otx_row = otx_counts.find { |r| r['date'] == date } || {}
        otx_row.each do |key, value|
          next if key == 'date'

          row["otx_#{key}"] = value.to_i
        end

        # Add URLhaus threat counts
        urlhaus_row = urlhaus_counts.find { |r| r['date'] == date } || {}
        urlhaus_row.each do |key, value|
          next if key == 'date'

          row["urlhaus_#{key}"] = value.to_i
        end

        # Add NVD vulnerability stats
        nvd_row = nvd_stats.find { |r| r['date'] == date } || {}
        row['nvd_count'] = nvd_row['count'].to_i
        row['nvd_severity'] = nvd_row['avg_severity'].to_f

        # Fill missing values with 0
        row.each { |k, v| row[k] = 0 if v.nil? }

        ts_data << row
      end

      # Calculate aggregate metrics
      ts_data.each do |row|
        # Sum all OTX indicators
        row['total_indicators'] = row.select { |k, _| k.start_with?('otx_') }.values.sum

        # Sum all URLhaus threats
        row['total_threats'] = row.select { |k, _| k.start_with?('urlhaus_') }.values.sum

        # Calculate threat severity index
        row['threat_severity_index'] = (
          (row['total_indicators'] * 0.4) +
          (row['total_threats'] * 0.4) +
          (row['nvd_count'] * row['nvd_severity'] * 0.2)
        )
      end

      # Save prepared time series data
      save_to_csv(ts_data, "#{@storage_path}/prepared_time_series_data.csv")

      # Format specifically for Prophet
      prophet_data = ts_data.map do |row|
        { 'ds' => row['date'], 'y' => row['threat_severity_index'] }
      end

      save_to_csv(prophet_data, "#{@storage_path}/prophet_input_data.csv")

      ts_data.length
    rescue StandardError => e
      puts "Error preparing time series data: #{e}"
      0
    end
  end

  def prepare_classification_data
    puts 'Preparing classification features...'

    begin
      # Load indicators from different sources
      otx_indicators = load_csv("#{@storage_path}/alienvault_indicators.csv")
      urlhaus_data = load_csv("#{@storage_path}/urlhaus_urls.csv")

      # Process URL-based indicators from OTX
      url_indicators = otx_indicators.select { |ind| ind['type'] == 'URL' }
      url_indicators.each do |ind|
        ind['source'] = 'otx'
        tags = ind['pulse_tags'].to_s.downcase

        ind['label'] = if tags.include?('phishing')
                         'phishing'
                       elsif tags.include?('malware')
                         'malware'
                       elsif tags.include?('ransomware')
                         'ransomware'
                       else
                         'other'
                       end
      end

      # Process URLhaus data
      urlhaus_urls = urlhaus_data.map do |row|
        {
          'url' => row['url'],
          'source' => 'urlhaus',
          'label' => row['threat'],
        }
      end

      # Extract features from URLs
      def extract_url_features(url_data)
        url_data.map do |item|
          url = item['url'].to_s
          features = {}

          # Length-based features
          features['url_length'] = url.length

          # Domain-based features
          domain_match = url.match(%r{https?://([^/]+)})
          features['domain_length'] = domain_match ? domain_match[1].length : 0

          # Path-based features
          path_match = url.match(%r{https?://[^/]+(/[^\?]*)})
          features['path_length'] = path_match ? path_match[1].length : 0

          # Query-based features
          features['has_query'] = url.include?('?') ? 1 : 0

          # Security indicators
          features['has_https'] = url.start_with?('https') ? 1 : 0

          # Suspicious patterns
          features['has_ip_address'] = url.match?(%r{https?://\d+\.\d+\.\d+\.\d+}) ? 1 : 0
          features['suspicious_keywords'] = url.match?(/login|account|secure|bank|paypal|verify|update/i) ? 1 : 0

          # Add label
          features['label'] = item['label']

          features
        end
      end

      # Apply feature extraction
      otx_url_features = extract_url_features(url_indicators)
      urlhaus_url_features = extract_url_features(urlhaus_urls)

      # Combine features and save
      combined_features = otx_url_features + urlhaus_url_features
      save_to_csv(combined_features, "#{@storage_path}/url_classification_features.csv")

      combined_features.length
    rescue StandardError => e
      puts "Error preparing classification data: #{e}"
      0
    end
  end

  def prepare_anomaly_detection_data
    puts 'Preparing anomaly detection datasets...'

    begin
      # For this example, we'll create a synthetic dataset that mimics network flow data
      n_samples = 10_000
      n_normal = (n_samples * 0.95).to_i  # 95% normal traffic
      n_anomalous = n_samples - n_normal  # 5% anomalous

      # Generate normal traffic patterns
      normal_data = []
      n_normal.times do
        normal_data << {
          'duration' => Distribution::Gamma.rng(1.5, 2.0),
          'protocol' => ['TCP', 'UDP', 'ICMP'].sample(weights: [0.8, 0.15, 0.05]),
          'src_port' => rand(1024..65_535),
          'dst_port' => [80, 443, 22, 53, 123, 25,
                         *rand(1024..65_535),].sample(weights: [0.3, 0.3, 0.05, 0.1, 0.02, 0.03, 0.2]),
          'packet_count' => Math.exp(Distribution::Normal.rng(3.0, 1.0)),
          'byte_count' => Math.exp(Distribution::Normal.rng(7.0, 1.5)),
          'is_anomaly' => 0,
        }
      end

      # Generate anomalous traffic patterns
      anomalous_data = []
      n_anomalous.times do
        anomalous_data << {
          'duration' => Distribution::Gamma.rng(0.8, 10.0), # Different distribution
          'protocol' => ['TCP', 'UDP', 'ICMP'].sample(weights: [0.5, 0.2, 0.3]), # More ICMP
          'src_port' => rand(1..1023), # Low ports (unusual)
          'dst_port' => [80, 443, 22, 4444, 5555, 9999].sample(weights: [0.1, 0.1, 0.1, 0.3, 0.2, 0.2]),
          'packet_count' => Math.exp(Distribution::Normal.rng(5.0, 2.0)), # More packets
          'byte_count' => Math.exp(Distribution::Normal.rng(9.0, 2.0)), # More bytes
          'is_anomaly' => 1,
        }
      end

      # Combine normal and anomalous data
      combined_data = normal_data + anomalous_data

      # Shuffle the data
      combined_data.shuffle!

      # Add derived features
      combined_data.each do |flow|
        flow['bytes_per_packet'] = flow['byte_count'] / flow['packet_count']
        flow['packets_per_second'] = flow['packet_count'] / flow['duration']

        # Convert protocol to numeric
        flow['protocol_tcp'] = flow['protocol'] == 'TCP' ? 1 : 0
        flow['protocol_udp'] = flow['protocol'] == 'UDP' ? 1 : 0
        flow['protocol_icmp'] = flow['protocol'] == 'ICMP' ? 1 : 0

        # Create port categories
        flow['src_port_system'] = flow['src_port'] < 1024 ? 1 : 0
        flow['dst_port_web'] = [80, 443].include?(flow['dst_port']) ? 1 : 0
        flow['dst_port_common'] = [22, 53, 123, 25].include?(flow['dst_port']) ? 1 : 0
        flow['dst_port_unusual'] = [4444, 5555, 9999].include?(flow['dst_port']) ? 1 : 0
      end

      # Save the synthetic dataset
      save_to_csv(combined_data, "#{@storage_path}/synthetic_network_flows.csv")

      # Create training and test sets

      # Stratified split (maintain anomaly ratio)
      normal_flows = combined_data.select { |flow| flow['is_anomaly'] == 0 }
      anomalous_flows = combined_data.select { |flow| flow['is_anomaly'] == 1 }

      normal_train = normal_flows.slice(0, (normal_flows.length * 0.8).to_i)
      normal_test = normal_flows.slice(normal_train.length, normal_flows.length)

      anomalous_train = anomalous_flows.slice(0, (anomalous_flows.length * 0.8).to_i)
      anomalous_test = anomalous_flows.slice(anomalous_train.length, anomalous_flows.length)

      train_data = normal_train + anomalous_train
      test_data = normal_test + anomalous_test

      # Shuffle again
      train_data.shuffle!
      test_data.shuffle!

      # Save the datasets
      save_to_csv(train_data, "#{@storage_path}/anomaly_train_data.csv")
      save_to_csv(test_data, "#{@storage_path}/anomaly_test_data.csv")

      combined_data.length
    rescue StandardError => e
      puts "Error preparing anomaly detection data: #{e}"
      0
    end
  end

  def prepare_sequence_data_for_lstm
    puts 'Preparing sequence data for LSTM...'

    begin
      # Define attack stages (simplified MITRE ATT&CK tactics)
      attack_stages = [
        'initial_access', 'execution', 'persistence', 'privilege_escalation',
        'defense_evasion', 'credential_access', 'discovery', 'lateral_movement',
        'collection', 'command_and_control', 'exfiltration', 'impact',
      ]

      # Create synthetic attack sequences
      num_sequences = 1000
      max_seq_length = 10

      sequences = []
      labels = [] # 0: benign, 1: malicious

      # Generate benign sequences (more predictable patterns)
      (num_sequences / 2).times do
        sequence = []

        # Common benign patterns
        if rand < 0.7
          # Authentication followed by discovery and some actions
          sequence = ['initial_access', 'execution', 'discovery']
          sequence << 'collection' if rand < 0.5
          sequence << 'privilege_escalation' if rand < 0.3
        else
          # Random but limited selection of activities
          seq_len = rand(3..6)
          seq_len.times do
            # Benign sequences less likely to have certain stages
            benign_stages = attack_stages - [
              'defense_evasion', 'credential_access', 'lateral_movement',
              'exfiltration', 'impact',
            ]
            sequence << benign_stages.sample
          end
        end

        sequences << sequence
        labels << 0 # Benign
      end

      # Generate malicious sequences (more varied patterns)
      (num_sequences / 2).times do
        sequence = []

        # Typical attack patterns
        if rand < 0.6
          # Full attack chain
          base_sequence = [
            'initial_access', 'execution', 'persistence',
            'privilege_escalation', 'defense_evasion',
          ]

          # Add post-compromise activities
          post_activities = [
            'credential_access', 'discovery', 'lateral_movement',
            'collection', 'command_and_control', 'exfiltration', 'impact',
          ]

          # Select a subset of post-activities
          num_post = rand(2..post_activities.length)
          selected_post = post_activities.sample(num_post)

          sequence = base_sequence + selected_post
          sequence = sequence[0...max_seq_length] if sequence.length > max_seq_length
        else
          # Random selection of activities (more varied)
          seq_len = rand(5..max_seq_length)
          seq_len.times do |j|
            # Ensure some malicious indicators appear
            sequence << if j == 0
                          'initial_access'
                        elsif j == seq_len - 1
                          ['impact', 'exfiltration', 'command_and_control'].sample
                        else
                          attack_stages.sample
                        end
          end
        end

        sequences << sequence
        labels << 1 # Malicious
      end

      # Convert attack stages to numeric indices
      stage_to_idx = {}
      attack_stages.each_with_index do |stage, idx|
        stage_to_idx[stage] = idx + 1 # Start from 1, leave 0 for padding
      end

      # Pad sequences to max_seq_length
      padded_sequences = []
      sequences.each do |seq|
        padded = seq.map { |stage| stage_to_idx[stage] }
        if padded.length < max_seq_length
          padded += [0] * (max_seq_length - padded.length) # Pad with zeros
        elsif padded.length > max_seq_length
          padded = padded[0...max_seq_length]
        end
        padded_sequences << padded
      end

      # Save the sequence data
      File.write("#{@storage_path}/attack_sequences_X.json", padded_sequences.to_json)
      File.write("#{@storage_path}/attack_sequences_y.json", labels.to_json)

      # Save mapping for reference
      File.write("#{@storage_path}/attack_stage_mapping.json", stage_to_idx.to_json)

      # Split into train/test sets

      # Stratified split
      benign_indices = []
      malicious_indices = []

      labels.each_with_index do |label, idx|
        if label == 0
          benign_indices << idx
        else
          malicious_indices << idx
        end
      end

      benign_train = benign_indices.shuffle[0...(benign_indices.length * 0.8).to_i]
      benign_test = benign_indices - benign_train

      malicious_train = malicious_indices.shuffle[0...(malicious_indices.length * 0.8).to_i]
      malicious_test = malicious_indices - malicious_train

      train_indices = benign_train + malicious_train
      test_indices = benign_test + malicious_test

      # Create train/test datasets
      x_train = train_indices.map { |idx| padded_sequences[idx] }
      y_train = train_indices.map { |idx| labels[idx] }

      x_test = test_indices.map { |idx| padded_sequences[idx] }
      y_test = test_indices.map { |idx| labels[idx] }

      # Save train/test sets
      File.write("#{@storage_path}/attack_sequences_X_train.json", x_train.to_json)
      File.write("#{@storage_path}/attack_sequences_y_train.json", y_train.to_json)
      File.write("#{@storage_path}/attack_sequences_X_test.json", x_test.to_json)
      File.write("#{@storage_path}/attack_sequences_y_test.json", y_test.to_json)

      sequences.length
    rescue StandardError => e
      puts "Error preparing sequence data: #{e}"
      0
    end
  end

  def prepare_graph_data
    puts 'Preparing graph data for GNN models...'

    begin
      # Load MITRE ATT&CK data
      techniques = load_csv("#{@storage_path}/mitre_techniques.csv")
      relationships = load_csv("#{@storage_path}/mitre_relationships.csv")

      # Create a mapping of technique IDs to numeric indices
      technique_ids = techniques.map { |t| t['id'] }.uniq
      id_to_idx = {}
      technique_ids.each_with_index { |id, idx| id_to_idx[id] = idx }

      # Create edge list (source, target) for technique relationships
      edges = []
      edge_types = []

      relationships.each do |rel|
        source = rel['source_ref']
        target = rel['target_ref']
        rel_type = rel['relationship_type']

        # Only include relationships between techniques
        if id_to_idx.key?(source) && id_to_idx.key?(target)
          edges << [id_to_idx[source], id_to_idx[target]]
          edge_types << rel_type
        end
      end

      # Create node features
      node_features = []
      techniques.each do |tech|
        # Extract features from techniques
        tactics = tech['tactics'].to_s.split(',')

        # One-hot encode tactics
        all_tactics = [
          'initial-access', 'execution', 'persistence', 'privilege-escalation',
          'defense-evasion', 'credential-access', 'discovery', 'lateral-movement',
          'collection', 'command-and-control', 'exfiltration', 'impact',
        ]

        tactic_features = all_tactics.map { |t| tactics.include?(t) ? 1 : 0 }

        # Add description-based features (simplified)
        desc = tech['description'].to_s.downcase
        has_network = desc.include?('network') ? 1 : 0
        has_file = desc.include?('file') ? 1 : 0
        has_registry = desc.include?('registry') ? 1 : 0
        has_process = desc.include?('process') ? 1 : 0
        has_credential = desc.include?('credential') || desc.include?('password') ? 1 : 0
        # Combined feature vector
        features = tactic_features + [has_network, has_file, has_registry, has_process, has_credential]
        node_features << features
      end

      # Save graph data for GNN
      graph_data = {
        'node_features' => node_features,
        'edges' => edges,
        'edge_types' => edge_types,
        'id_to_idx' => id_to_idx,
      }

      File.write("#{@storage_path}/attack_graph_data.json", graph_data.to_json)

      node_features.length
    rescue StandardError => e
      puts "Error preparing graph data: #{e}"
      0
    end
  end

  private

  def save_to_csv(data, filename)
    return if data.empty?

    CSV.open(filename, 'w') do |csv|
      csv << data.first.keys
      data.each do |row|
        csv << row.values
      end
    end
  end

  def load_csv(filename)
    return [] unless File.exist?(filename)

    CSV.read(filename, headers: true)
  end
end
