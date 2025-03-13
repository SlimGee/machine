class Analysis::PatternMatcher
  def self.match(indicator)
    # Match indicator against known patterns
    matches = []

    # Different matching strategies based on indicator type
    case indicator.indicator_type
    when "ip_address"
      matches.concat(match_ip_address(indicator))
    when "domain"
      matches.concat(match_domain(indicator))
    when "file_hash"
      matches.concat(match_file_hash(indicator))
    when "url"
      matches.concat(match_url(indicator))
    when "email"
      matches.concat(match_email(indicator))
    end

    # Add generic pattern matches
    matches.concat(match_generic_patterns(indicator))

    matches
  end

  private

    def self.match_ip_address(indicator)
      matches = []
      ip = indicator.value

      # Check against known malicious IP ranges
      malicious_ranges = MaliciousIpRange.all
      malicious_ranges.each do |range|
        if IPAddr.new(range.cidr).include?(IPAddr.new(ip))
          matches << {
            pattern_type: "malicious_ip_range",
            confidence: range.confidence / 100.0,
            severity_weight: 0.8,
            event_type: "network_connection",
            mitre_tactic_id: "TA0011", # Command and Control
            threat_actor: range.threat_actor
          }
        end
      end

      # Check for Tor exit nodes
      if TorExitNode.exists?(ip: ip)
        matches << {
          pattern_type: "tor_exit_node",
          confidence: 0.9,
          severity_weight: 0.6,
          event_type: "anonymization",
          mitre_tactic_id: "TA0008" # Lateral Movement
        }
      end

      # Check for known C2 servers
      if CommandAndControlServer.exists?(ip: ip)
        c2_server = CommandAndControlServer.find_by(ip: ip)
        matches << {
          pattern_type: "command_and_control",
          confidence: 0.95,
          severity_weight: 0.9,
          event_type: "command_and_control",
          mitre_tactic_id: "TA0011", # Command and Control
          threat_actor: c2_server.threat_actor
        }
      end

      matches
    end

    def self.match_domain(indicator)
      matches = []
      domain = indicator.value

      # Check against known malicious domains
      if MaliciousDomain.exists?(domain: domain)
        mal_domain = MaliciousDomain.find_by(domain: domain)
        matches << {
          pattern_type: "malicious_domain",
          confidence: mal_domain.confidence / 100.0,
          severity_weight: 0.8,
          event_type: "dns_request",
          mitre_tactic_id: "TA0011", # Command and Control
          threat_actor: mal_domain.threat_actor
        }
      end

      # Check for DGA (Domain Generation Algorithm) patterns
      if domain.length > 20 && domain.match?(/[0-9a-f]{10,}/)
        matches << {
          pattern_type: "dga_domain",
          confidence: 0.7,
          severity_weight: 0.7,
          event_type: "dns_request",
          mitre_tactic_id: "TA0011" # Command and Control
        }
      end

      # Check for typosquatting domains
      typosquat_target = check_typosquatting(domain)
      if typosquat_target
        matches << {
          pattern_type: "typosquatting",
          confidence: 0.8,
          severity_weight: 0.7,
          event_type: "phishing_preparation",
          mitre_tactic_id: "TA0001", # Initial Access
          context: { target_domain: typosquat_target }
        }
      end

      matches
    end

    def self.match_file_hash(indicator)
      matches = []
      file_hash = indicator.value

      # Check against known malware hashes
      if MalwareHash.exists?(hash: file_hash)
        malware = MalwareHash.find_by(hash: file_hash)
        matches << {
          pattern_type: "malware_hash",
          confidence: 0.95,
          severity_weight: 0.9,
          event_type: "malware_detected",
          mitre_tactic_id: "TA0002", # Execution
          threat_actor: malware.threat_actor
        }
      end

      matches
    end

    def self.match_url(indicator)
      matches = []
      url = indicator.value

      # Check for phishing URLs
      if url.match?(/login|account|secure|update|verify/)
        # Parse domain from URL
        domain = extract_domain_from_url(url)

        # Check if this is a lookalike domain for a high-value target
        lookalike_target = check_typosquatting(domain)

        if lookalike_target
          matches << {
            pattern_type: "phishing_url",
            confidence: 0.8,
            severity_weight: 0.8,
            event_type: "phishing",
            mitre_tactic_id: "TA0001", # Initial Access
            context: { target_domain: lookalike_target }
          }
        end
      end

      # Check for exploit kit URLs
      if url.match?(/\.js$|eval\(|document\.write\(|unescape\(|fromCharCode/)
        matches << {
          pattern_type: "exploit_kit_url",
          confidence: 0.7,
          severity_weight: 0.8,
          event_type: "exploit_attempt",
          mitre_tactic_id: "TA0002" # Execution
        }
      end

      matches
    end

    def self.match_email(indicator)
      matches = []
      email = indicator.value

      # Check for suspicious sender domains
      domain = email.split("@").last

      if domain && MaliciousDomain.exists?(domain: domain)
        mal_domain = MaliciousDomain.find_by(domain: domain)
        matches << {
          pattern_type: "malicious_email_domain",
          confidence: mal_domain.confidence / 100.0,
          severity_weight: 0.7,
          event_type: "phishing",
          mitre_tactic_id: "TA0001", # Initial Access
          threat_actor: mal_domain.threat_actor
        }
      end

      # Check for lookalike domains in email addresses
      if domain
        typosquat_target = check_typosquatting(domain)
        if typosquat_target
          matches << {
            pattern_type: "email_typosquatting",
            confidence: 0.8,
            severity_weight: 0.7,
            event_type: "phishing",
            mitre_tactic_id: "TA0001", # Initial Access
            context: { target_domain: typosquat_target }
          }
        end
      end

      matches
    end

    def self.match_generic_patterns(indicator)
      matches = []

      # Check recency - newer indicators are more significant
      if indicator.first_seen && indicator.first_seen > 24.hours.ago
        matches << {
          pattern_type: "recent_indicator",
          confidence: 0.6,
          severity_weight: 0.5,
          event_type: "new_threat_indicator"
        }
      end

      # Check for indicators reported by multiple sources
      source_count = indicator.source_id.present? ? 1 : 0
      if source_count > 2
        matches << {
          pattern_type: "multiple_source_confirmation",
          confidence: 0.7,
          severity_weight: 0.6,
          event_type: "confirmed_threat_indicator"
        }
      end

      matches
    end

    def self.check_typosquatting(domain)
      # Check if domain is typosquatting a known target
      high_value_domains = [ "google.com", "microsoft.com", "apple.com", "amazon.com", "facebook.com", "paypal.com", "chase.com", "wellsfargo.com" ]

      high_value_domains.each do |target_domain|
        # Simple Levenshtein distance check
        distance = levenshtein_distance(domain, target_domain)

        # If domains are similar but not identical
        if distance > 0 && distance <= 2
          return target_domain
        end
      end

      nil
    end

    def self.extract_domain_from_url(url)
      # Simple URL parsing to extract domain
      begin
        uri = URI.parse(url)
        host = uri.host

        # Remove www prefix if present
        host = host.sub(/^www\./, "") if host

        host
      rescue URI::InvalidURIError
        # If can't parse as URI, try simple regex
        url.match(/https?:\/\/(?:www\.)?([^\/]+)/)&.captures&.first
      end
    end

    def self.levenshtein_distance(s, t)
      # Calculate Levenshtein distance between two strings
      m = s.length
      n = t.length

      return m if n == 0
      return n if m == 0

      d = Array.new(m + 1) { Array.new(n + 1) }

      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }

      (1..n).each do |j|
        (1..m).each do |i|
          d[i][j] = if s[i-1] == t[j-1]
            d[i-1][j-1]
          else
            [ d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + 1 ].min
          end
        end
      end

      d[m][n]
    end
end
