namespace :intel do
  task gather: :environment do
    Ingestion::ThreatFeeds::Collector.collect
  end

  task process: :environment do
    Rails.logger.info("Starting autonomous analysis")

    # Run the autonomous analyzer
    Analysis::Engine.analyze_new_indicators
  end

  task import_patterns: :environment do
    conn =  Faraday.new("https://raw.githubusercontent.com/mitre/cti/refs/heads/master/enterprise-attack/enterprise-attack.json") do |f|
      f.request :json
      f.response :json
    end

    response = conn.get
    tactics = ActiveSupport::JSON.decode(response.body)["objects"]
    tactics.each do |tactic|
      begin
        mitre_id = tactic["external_references"].find { |ref| ref["source_name"] == "mitre-attack" }["external_id"]
      rescue
        next
      end

      existing_tactic = Tactic.find_by(mitre_id: mitre_id)

      if existing_tactic
        existing_tactic.update(
          name: tactic["name"],
          description: tactic["description"]
        )
      else
        Tactic.create!(
          mitre_id: mitre_id,
          name: tactic["name"],
          description: tactic["description"]
        )
      end
    end
  end
end
