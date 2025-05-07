# frozen_string_literal: true

class GenerateEmbeddingsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Rails.logger.info 'Generating embeddings for all models'
    [Asset, Correlation, Event, Indicator, MaliciousDomain, Malware, Prediction, Source, Tactic, ThreatActor, Target,
     Vulnerability].each do |model|
      model.embed!
      Rails.logger.info "Generating embeddings for #{model}..."
      sleep 1
    rescue StandardError
      next
    end
  end
end
