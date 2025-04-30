class Analysis::EventCorrelator
  def self.correlate(indicator)
    # Find correlations between this indicator and existing events
    correlations = []

    # Find events with related indicators
    related_events = find_related_events(indicator)

    related_events.each do |event|
      confidence = calculate_correlation_confidence(indicator, event)

      if confidence >= 0.5 # Only record significant correlations
        correlation = {
          event_id: event.id,
          confidence: confidence,
          relationship_type: determine_relationship_type(indicator, event),
          threat_actors: event.threat_actors.map { |actor| { name: actor.name, confidence: actor.confidence.to_f / 100 } }
        }

        correlations << correlation

        # Create a correlation record if confidence is high enough
        if confidence >= 0.7
          create_correlation_record(indicator, event, correlation)
        end
      end
    end

    correlations
  end

  private
    def self.find_related_events(indicator)
      case indicator.indicator_type
      when "ip_address"
        # Find events with the same or related IPs
        ip_base = indicator.value.split(".")[0..2].join(".")
        related_indicators = Indicator.where(indicator_type: "ip_address")
                                     .where("value LIKE ?", "#{ip_base}.%")

        Event.joins(:indicators)
             .where(indicators: { id: related_indicators.pluck(:id) })
             .distinct

      when "domain"
        # Find events with the same or related domains
        domain_parts = indicator.value.split(".")
        if domain_parts.size >= 2
          base_domain = domain_parts[-2..-1].join(".")
          related_indicators = Indicator.where(indicator_type: "domain")
                                       .where("value LIKE ?", "%.#{base_domain}")

          Event.joins(:indicators)
               .where(indicators: { id: related_indicators.pluck(:id) })
               .distinct
        else
          Event.none
        end

      when "file_hash"
        # Find events with the same file hash
        Event.joins(:indicators)
             .where(indicators: { indicator_type: "file_hash", value: indicator.value })
             .distinct

      else
        # For other indicator types, find events with the exact same indicator
        Event.joins(:indicators)
             .where(indicators: { indicator_type: indicator.indicator_type, value: indicator.value })
             .distinct
      end
    end

    def self.calculate_correlation_confidence(indicator, event)
      # Calculate how confident we are in the correlation
      base_confidence = 0.5

      # Adjust based on indicator type match
      event_indicators = event.indicators
      exact_type_matches = event_indicators.where(indicator_type: indicator.indicator_type).count
      base_confidence += 0.1 if exact_type_matches > 0

      # Adjust based on exact value match
      exact_value_matches = event_indicators.where(value: indicator.value).count
      base_confidence += 0.2 if exact_value_matches > 0

      # Adjust based on temporal proximity
      if indicator.first_seen && event.timestamp
        time_diff = (indicator.first_seen - event.timestamp).abs
        if time_diff < 1.hour
          base_confidence += 0.2
        elsif time_diff < 24.hours
          base_confidence += 0.1
        elsif time_diff > 30.days
          base_confidence -= 0.1
        end
      end

      # Adjust based on tactic match

      # Cap confidence at 0.95
      [ base_confidence, 0.95 ].min
    end

    def self.determine_relationship_type(indicator, event)
      # Determine the relationship between indicator and event

      # Check if indicator comes before or after event
      if indicator.first_seen && event.timestamp
        if indicator.first_seen < event.timestamp
          return "indicator_precedes_event"
        else
          return "event_precedes_indicator"
        end
      end

      # Check if indicator is same type as any in the event
      event_indicator_types = event.indicators.pluck(:indicator_type).uniq
      if event_indicator_types.include?(indicator.indicator_type)
        return "same_indicator_type"
      end

      # Default relationship
      "related"
    end

    def self.create_correlation_record(indicator, event, correlation_data)
      # Find or create another event for this indicator
      indicator_event = Event.joins(:indicators)
                            .where(indicators: { id: indicator.id })
                            .first

      # If no event exists for this indicator yet, don't create correlation
      return unless indicator_event

      # Don't create correlation between same events
      return if indicator_event.id == event.id

      # Create correlation record
      Correlation.find_or_create_by(
        first_event: indicator_event,
        second_event: event
      ) do |c|
        c.confidence = correlation_data[:confidence]
        c.relationship_type = correlation_data[:relationship_type]
        c.discovered_at = Time.current
      end
    end
end
