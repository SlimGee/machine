class Analysis::Engine
  def self.analyze_new_indicators
    new_indicators = Indicator.where("created_at > ?", 7.day.ago).where(indicator_type: :url)

    # Process each new indicator
    new_indicators.find_each do |indicator|
      # Check for pattern matches
      matches = find_pattern_matches(indicator)
      puts matches.inspect
      # Correlate with existing events
      correlations = correlate_with_events(indicator)
      puts correlations.inspect

      # Create new events if necessary
      create_events_from_indicator(indicator, matches)

      # Update threat actor profiles
      update_threat_actor_profiles(indicator, matches, correlations)

      # Run predictions for potentially affected targets
      run_predictions_for_targets(indicator)
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

    # Associate indicator with event
    EventIndicator.create!(
      event: event,
      indicator: indicator,
      context: "Automatically detected pattern match"
    )

    # Associate with tactic if identifiable
    if tactic = identify_tactic(matches)
      event.update(tactic: tactic)
    end

    event
  end

  def self.update_threat_actor_profiles(indicator, matches, correlations)
    # Update threat actor profiles based on new intelligence
    threat_actors = identify_threat_actors(indicator, matches, correlations)

    threat_actors.each do |actor_data|
      actor = ThreatActor.find_or_create_by(name: actor_data[:name])

      # Update actor profile
      actor.update(
        description: actor.description || "Threat actor identified by autonomous analysis",
        last_seen: Time.current,
        confidence: actor_data[:confidence]
      )

      # Connect to events if applicable
      if actor_data[:event_id]
        EventThreatActor.find_or_create_by(
          event_id: actor_data[:event_id],
          threat_actor: actor,
          confidence: actor_data[:confidence]
        )
      end
    end
  end

  def self.run_predictions_for_targets(indicator)
    # Identify potentially affected targets based on indicator
    targets = identify_potential_targets(indicator)

    # Run predictions for each potentially affected target
    targets.each do |target|
      # Use active prediction models
      active_models = MachineLearning::PredictionModel.where(status: :active)

      # For ensemble approach, combine predictions from all models
      prediction_results = active_models.map do |model|
        model.predict(target)
      end

      # Evaluate if prediction warrants creating a formal prediction record
      if should_create_prediction?(prediction_results)
        create_prediction(target, prediction_results)
      end
    end
  end

private

  def self.determine_event_type(matches)
    # Logic to determine event type based on pattern matches
    highest_confidence_match = matches.max_by { |match| match[:confidence] }
    highest_confidence_match[:event_type] || "suspicious_activity"
  end

  def self.determine_severity(matches)
    # Calculate severity based on match confidence and pattern severity
    severity_score = matches.sum { |match| match[:confidence] * match[:severity_weight] }

    if severity_score > 0.8
      "critical"
    elsif severity_score > 0.6
      "high"
    elsif severity_score > 0.4
      "medium"
    else
      "low"
    end
  end

  def self.identify_tactic(matches)
    # Try to identify MITRE ATT&CK tactic from matches
    tactic_matches = matches.select { |match| match[:mitre_tactic_id].present? }
    return nil if tactic_matches.empty?

    # Use the highest confidence tactic match
    best_match = tactic_matches.max_by { |match| match[:confidence] }
    Tactic.find_by(mitre_id: best_match[:mitre_tactic_id])
  end

  def self.identify_threat_actors(indicator, matches, correlations)
    # Identify potential threat actors based on TTP matches and correlations
    threat_actors = []

    # Extract threat actors from pattern matches
    matches.each do |match|
      if match[:threat_actor].present?
        threat_actors << {
          name: match[:threat_actor],
          confidence: match[:confidence],
          event_id: match[:event_id]
        }
      end
    end

    # Extract threat actors from correlations
    correlations.each do |correlation|
      correlation[:threat_actors].each do |actor|
        threat_actors << {
          name: actor[:name],
          confidence: actor[:confidence] * correlation[:confidence],
          event_id: correlation[:event_id]
        }
      end
    end

    # Consolidate duplicate actors by taking max confidence
    consolidated_actors = {}
    threat_actors.each do |actor|
      existing = consolidated_actors[actor[:name]]
      if existing.nil? || existing[:confidence] < actor[:confidence]
        consolidated_actors[actor[:name]] = actor
      end
    end

    consolidated_actors.values
  end

  def self.identify_potential_targets(indicator)
    # Identify potential targets based on indicator type and value
    case indicator.indicator_type
    when "ip_address"
      # Find targets with assets using this IP
      targets = Target.joins(:assets).where(assets: { identifier: indicator.value })

      # Also find targets in the same network range
      ip_network = indicator.value.split(".")[0..2].join(".")
      similar_assets = Asset.where("identifier LIKE ?", "#{ip_network}.%")
      network_targets = Target.where(id: similar_assets.select(:target_id))

      targets = (targets + network_targets).uniq
    when "domain"
      # Find targets with this domain in their assets
      targets = Target.joins(:assets).where(assets: { identifier: indicator.value })

      # Also find targets with similar domains
      domain_parts = indicator.value.split(".")
      if domain_parts.size >= 2
        base_domain = domain_parts[-2..-1].join(".")
        similar_assets = Asset.where("identifier LIKE ?", "%.#{base_domain}")
        domain_targets = Target.where(id: similar_assets.select(:target_id))

        targets = (targets + domain_targets).uniq
      end
    when "file_hash"
      # Find targets with this file hash in their assets
      targets = Target.joins(:assets).where(assets: { identifier: indicator.value })
    else
      # For other indicator types, use a broader approach
      # For example, check if any targets in the same industry as previously affected targets
      affected_target_industries = []

      targets = Target.where(industry: affected_target_industries)
    end

    # If no specific targets found, return high-value targets for general monitoring
    if targets.empty?
      targets = Target.where("risk_score > ?", 0.7).limit(10)
    end

    targets
  end

  def self.should_create_prediction?(prediction_results)
    # Evaluate prediction results to determine if a formal prediction should be created
    # Use a consensus approach from multiple models

    # Calculate average risk score
    avg_risk_score = prediction_results.sum { |result| result[:risk_score] } / prediction_results.size.to_f

    # Only create predictions for significant risk
    avg_risk_score > 0.5
  end

  def self.create_prediction(target, prediction_results)
    # Aggregate prediction results
    aggregated = aggregate_predictions(prediction_results)

    # Find the most likely threat actor
    threat_actor = ThreatActor.find_by(name: aggregated[:most_likely_threat_actor])
    return unless threat_actor # Skip if we can't identify a threat actor

    # Find the most likely technique
    technique = Technique.find_by(mitre_id: aggregated[:most_likely_technique])
    return unless technique # Skip if we can't identify a technique

    # Create the prediction record
    Prediction.create!(
      threat_actor: threat_actor,
      target: target,
      technique: technique,
      confidence: aggregated[:confidence],
      estimated_timeframe: aggregated[:estimated_timeframe],
      prediction_date: Time.current
    )
  end

  def self.aggregate_predictions(prediction_results)
    # Aggregate predictions from multiple models

    # Calculate overall confidence (average)
    confidence = prediction_results.sum { |result| result[:probability] } / prediction_results.size.to_f

    # Find most likely threat actor (weighted voting)
    threat_actor_votes = {}
    prediction_results.each do |result|
      result[:likely_threat_actors].each do |actor|
        threat_actor_votes[actor[:name]] ||= 0
        threat_actor_votes[actor[:name]] += actor[:confidence]
      end
    end
    most_likely_threat_actor = threat_actor_votes.max_by { |_, votes| votes }&.first

    # Find most likely technique (weighted voting)
    technique_votes = {}
    prediction_results.each do |result|
      result[:likely_techniques].each do |technique|
        technique_votes[technique[:mitre_id]] ||= 0
        technique_votes[technique[:mitre_id]] += technique[:confidence]
      end
    end
    most_likely_technique = technique_votes.max_by { |_, votes| votes }&.first

    # Find consensus on timeframe (median)
    timeframes = prediction_results.map { |result| result[:estimated_timeframe] }.sort
    estimated_timeframe = timeframes[timeframes.size / 2]

    {
      confidence: confidence,
      most_likely_threat_actor: most_likely_threat_actor,
      most_likely_technique: most_likely_technique,
      estimated_timeframe: estimated_timeframe
    }
  end
end
