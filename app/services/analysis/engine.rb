class Analysis::Engine
  def self.analyze_new_indicators
    query = Indicator.where('updated_at > ?', 30.days.ago).where(analysed: false)

    query.find_in_batches(batch_size: 1000) do |indicators|
      Parallel.each(indicators, in_threads: 16) do |indicator|
        ActiveRecord::Base.connection_pool.with_connection do
          matches = find_pattern_matches(indicator)

          correlations = correlate_with_events(indicator)

          event = create_events_from_indicator(indicator, matches)

          malware = update_malware_profile(indicator, matches, event)

          threat_actors = update_threat_actor_profiles(indicator, matches, correlations, event, malware)

          run_predictions_for_targets(indicator, threat_actors)

          indicator.update(analysed: true)
        rescue StandardError => e
          puts "Error processing indicator #{indicator.value}: #{e.inspect}"
          next
        end
      end
    end
  end

  def self.find_pattern_matches(indicator)
    Analysis::PatternMatcher.match(indicator)
  end

  def self.correlate_with_events(indicator)
    Analysis::EventCorrelator.correlate(indicator)
  end

  def self.create_events_from_indicator(indicator, matches)
    return if matches.empty?

    # Create a new event based on pattern matches
    event = Event.create!(
      event_type: determine_event_type(matches),
      timestamp: indicator.first_seen || Time.current,
      description: "Event detected based on indicator #{indicator.value} [#{indicator.indicator_type}]",
      severity: determine_severity(matches)
    )

    identify_tactics(matches).each do |tactic_id|
      EventTactic.create!(
        event: event,
        tactic_id: tactic_id
      )
    end

    # Associate indicator with event
    EventIndicator.create!(
      event: event,
      indicator: indicator,
      context: 'Automatically detected pattern match'
    )

    event
  end

  def self.update_malware_profile(indicator, matches, event)
    malware = matches.map { |match| match[:malware_families] }

    malware.flatten.map do |family|
      next if family.blank?

      instance = Malware.find_or_create_by(malware_id: family['id']) do |payload|
        payload.name = family['display_name']
        payload.target = family['target']
      end

      MalwareIndicator.find_or_create_by(
        malware: instance,
        indicator: indicator
      )

      MalwareEvent.find_or_create_by(
        malware: instance,
        event: event
      )

      instance
    end
  end

  def self.update_threat_actor_profiles(indicator, matches, correlations, event, malware)
    threat_actors = identify_threat_actors(indicator, matches, correlations)

    threat_actors.each do |actor|
      actor.update(last_seen: Time.current)

      actor.event_threat_actors.find_or_create_by(event: event)

      actor.threat_actor_indicators.find_or_create_by(indicator: indicator)

      malware.each do |malware_instance|
        actor.malware_threat_actors.find_or_create_by(malware: malware_instance)
      end
    end

    threat_actors
  end

  def self.run_predictions_for_targets(_indicator, threat_actors)
    TargetPredictionJob.perform_later(threat_actors)
  end

  def self.determine_event_type(matches)
    # Logic to determine event type based on pattern matches
    highest_confidence_match = matches.max_by { |match| match[:confidence] }
    highest_confidence_match[:event_type] || 'suspicious_activity'
  end

  def self.determine_severity(matches)
    # Calculate severity based on match confidence and pattern severity
    severity_score = matches.sum { |match| match[:confidence] * match[:severity_weight] }

    if severity_score > 0.8
      'critical'
    elsif severity_score > 0.6
      'high'
    elsif severity_score > 0.4
      'medium'
    else
      'low'
    end
  end

  def self.identify_tactics(matches)
    tactics = matches.flat_map do |match|
      match[:tactic_ids].presence
    end

    tactics.flatten.uniq.filter(&:presence)
  end

  def self.identify_threat_actors(_indicator, matches, correlations)
    # Identify potential threat actors based on TTP matches and correlations
    threat_actors = []

    # Extract threat actors from pattern matches
    matches.each do |match|
      next if match[:threat_actor].blank?

      match[:threat_actor].split(",").each do |actor|
        threat_actors << ThreatActor.find_or_create_by(name: actor) do |a|
          a.confidence = match[:confidence]
          a.last_seen = Time.current
        end
      end
    end

    # Extract threat actors from correlations
    correlations.each do |correlation|
      correlation[:threat_actors].each do |actor|
        threat_actors << ThreatActor.find_or_create_by(name: actor[:name]) do |a|
          a.description = actor[:description]
          a.confidence = actor[:confidence]
          a.last_seen = Time.current
        end
      end
    end

    threat_actors.uniq(&:id)
  end
end
