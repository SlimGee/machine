class Analysis::PatternMatcher
  def self.match(indicator)
    # Match indicator against known patterns
    matches = []

    # Different matching strategies based on indicator type
    case indicator.indicator_type
    when "ipaddress"
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

    matches
  end

  private
    def self.match_ip_address(indicator)
      matches = []
      ip = indicator.value

      otx = OTX::IP.new(Rails.application.credentials.dig(:otx, :key))
      ip_data = {}
      begin
        ip_data[:general] = otx.get_general(ip)
        ip_data[:reputation] = otx.get_reputation(ip)
        ip_data[:geo] = otx.get_geo(ip)
        ip_data[:malware] = otx.get_malware(ip)
        ip_data[:url_list] = otx.get_url_list(ip)
        ip_data[:passive_dns] = otx.get_passive_dns(ip)
        #  ip_data[:http_scans] = otx.get_http_scans(ip)
        ip_data[:general].pulse_info.pulses.filter do |pulse|
          pulse.attack_ids.any?
        end

        pulses = ip_data[:general].pulse_info.pulses
        threat_actors = pulses.filter_map { |pulse| pulse.adversary if pulse.adversary.present? }.uniq.join(", ")

        mitre_ids = pulses.filter_map do |pulse|
            pulse.attack_ids.map do |attack_id|
              attack_id["id"]
            end if pulse.attack_ids.any?
          end

        tactic_ids = Tactic.where(mitre_id: mitre_ids.flatten.uniq).pluck(:id)

        if ip_data[:reputation] && ip_data[:reputation].any?
          pulses = ip_data[:reputation].pulse_info.pulses
          # Calculate confidence based on number of reports
          confidence = [ pulses.size / 10.0, 0.9 ].min

          matches << {
            pattern_type: "malicious_ip_intel",
            confidence: confidence,
            severity_weight: 0.8,
            event_type: "network_connection",
            tactic_ids: tactic_ids,
            threat_actor: threat_actors.presence || "Unknown"
          }
        end

        # Process malware data
        if ip_data[:malware] && ip_data[:malware].any?
          malware_samples = ip_data[:malware]

          # Higher confidence with more malware samples
          confidence = [ malware_samples.size / 5.0, 0.95 ].min

          # Extract malware family names if available
          malware_families = malware_samples.map { |m| m.malware_hash }.compact.uniq

          matches << {
            pattern_type: "ip_hosts_malware",
            confidence: confidence,
            severity_weight: 0.9,
            event_type: "network_connection",
            tactic_ids: tactic_ids,
            malware_families: malware_families.presence || [ "Unknown" ],
            malware_count: malware_samples.size,
            threat_actor: threat_actors.presence || "Unknown"
          }
        end

        if ip_data[:url_list] && ip_data[:url_list].any?
          urls = ip_data[:url_list]

          # Extract domains from URLs
          domains = urls.map { |u| URI.parse(u.url).host rescue nil }.compact.uniq

          matches << {
            pattern_type: "suspicious_url_host",
            confidence: [ urls.size / 20.0, 0.8 ].min,
            severity_weight: 0.7,
            event_type: "network_connection",
            tactic_ids: tactic_ids,
            url_count: urls.size,
            threat_actor: threat_actors.presence || "Unknown",
            domains: domains.first(10) # Limit to first 10 domains
          }
        end

        if ip_data[:passive_dns] && ip_data[:passive_dns].any?
          dns_records = ip_data[:passive_dns]

          suspicious_domains = dns_records.select do |record|
            hostname = record.hostname.downcase
            MaliciousDomain.exists? name: hostname
          end

          if suspicious_domains.any?
            matches << {
              pattern_type: "suspicious_domain_pattern",
              confidence: 0.75,
              severity_weight: 0.7,
              tactic_ids: tactic_ids,
              event_type: "network_connection",
              threat_actor: threat_actors.presence || "Unknown",
              suspicious_domains: suspicious_domains.map { |d| d.hostname }.uniq
            }
          end
        end

        if ip_data[:geo] && ip_data[:geo].present?
          high_risk_countries = [ "RU", "CN", "IR", "KP", "VE" ]
          country_code = ip_data[:geo].country_code

          if high_risk_countries.include?(country_code)
            matches << {
              pattern_type: "high_risk_country",
              confidence: 0.6, # Lower confidence as geography alone isn't definitive
              severity_weight: 0.5,
              event_type: "network_connection",
              tactic_ids: tactic_ids,
              threat_actor: threat_actors.presence || "Unknown",
              country_code: country_code,
              country_name: ip_data[:geo].country_name
            }
          end
        end
      rescue Faraday::TimeoutError
        retry
      end

      matches
    end

    def self.match_domain(indicator)
      matches = []
      domain = indicator.value

      Check against known malicious domains
      if MaliciousDomain.exists?(name: domain)
        matches << {
          pattern_type: "malicious_domain",
          confidence: 0.7,
          severity_weight: 0.8,
          event_type: "dns_request",
          mitre_tactic_id: "TA0011", # Command and Control
          threat_actor: nil
        }
      end

      # Check for DGA (Domain Generation Algorithm) patterns
      if domain.length > 20 && domain.match?(/[0-9a-f]{10,}/)
        tactic = Tactic.find_by(mitre_id: "T1568.002")
        matches << {
          pattern_type: "dga_domain",
          confidence: 0.7,
          severity_weight: 0.7,
          event_type: "dns_request",
          mitre_tactic_id: tactic.mitre_id,
          tactic_id: tactic.id
        }
      end

      # Check for typosquatting domains
      typosquat_target = check_typosquatting(domain)
      if typosquat_target
        tactic = Tactic.find_by(mitre_id: "T1583.001")
        matches << {
          pattern_type: "typosquatting",
          confidence: 0.8,
          severity_weight: 0.7,
          event_type: "phishing_preparation",
          tactic_id: tactic.id,
          mitre_tactic_id: tactic.mitre_id,
          context: { target_domain: typosquat_target }
        }
      end

      matches
    end

    def self.match_file_hash(indicator)
      matches = []
      indicator.value

      # Check against known malware hashes
      #      if MalwareHash.exists?(hash: file_hash)
      #        malware = MalwareHash.find_by(hash: file_hash)
      #        matches << {
      #          pattern_type: "malware_hash",
      #          confidence: 0.95,
      #          severity_weight: 0.9,
      #          event_type: "malware_detected",
      #          mitre_tactic_id: "TA0002", # Execution
      #          threat_actor: malware.threat_actor
      #        }
      #      end

      matches
    end

    def self.match_url(indicator)
      matches = []
      url = indicator.value


      domain = extract_domain_from_url(url)

      if domain && MaliciousDomain.exists?(name: domain)
        matches << {
          pattern_type: "malicious_domain",
          confidence: 8.0,
          severity_weight: 0.7,
          event_type: "malicious_domain",
          mitre_tactic_id: "TA0001", # Initial Access
          threat_actor: nil
        }
      end

      # Check for phishing URLs
      if url.match?(/login|account|secure|update|verify/)
        # Parse domain from URL
        domain = extract_domain_from_url(url)

        # Check if this is a lookalike domain for a high-value target
        lookalike_target = check_typosquatting(domain)

        if lookalike_target

          tactic = Tactic.find_by(mitre_id: "T1566")
          matches << {
            pattern_type: "phishing_url",
            confidence: 0.8,
            severity_weight: 0.8,
            event_type: "phishing",
            tactic_id: tactic.id,
            mitre_tactic_id: tactic.mitre_id,
            context: { target_domain: lookalike_target }
          }
        end
      end

      # Check for exploit kit URLs
      if url.match?(/\.js$|eval\(|document\.write\(|unescape\(|fromCharCode/)
        tactic = Tactic.find_by(mitre_id: "T1189")
        matches << {
          pattern_type: "exploit_kit_url",
          confidence: 0.7,
          severity_weight: 0.8,
          event_type: "exploit_attempt",
          mitre_tactic_id: tactic.mitre_id,
          tactic_id: tactic.id
        }
      end



      matches
    end

    def self.match_email(indicator)
      matches = []
      email = indicator.value

      # Check for suspicious sender domains
      domain = email.split("@").last

      if domain && MaliciousDomain.exists?(name: domain)
        matches << {
          pattern_type: "malicious_email_domain",
          confidence: mal_domain.confidence / 100.0,
          severity_weight: 0.7,
          event_type: "phishing",
          mitre_tactic_id: "TA0001", # Initial Access
          threat_actor: nil
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
        return nil if target_domain.nil?

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

      unless URI.scheme_list.keys.map(&:downcase).any? { |scheme| url.downcase.start_with?(scheme) }
        url = "http://#{url}"
      end

      uri = URI.parse(url)

      host = uri.host

      # Remove www prefix if present
      host = host.sub(/^www\./, "") if host

      host
      rescue URI::InvalidURIError
        # If can't parse as URI, try simple regex
        url.match(/https?:\/\/(?:www\.)?([^\/]+)/)&.captures&.first
    end

    def self.levenshtein_distance(s, t)
      return 0 if s.blank?
      puts "s: #{s}"
      puts "t: #{t}"
      Text::Levenshtein.distance(s, t)
    end
end
