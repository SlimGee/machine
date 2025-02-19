namespace :intel do
  task gather: :environment do
    orchestrator = Ingestion::Gather::ThreatIntelOrchestrator.new

    orchestrator.collect_all_data
    orchestrator.prepare_final_datasets
  end
end
