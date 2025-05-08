class TargetPredictionJob < ApplicationJob
  queue_as :predictions

  limits_concurrency to: 1, key: :target_prediction_job

  def perform(threat_actors)
    threat_actors.each do |actor|
      prediction_results = Predict::DefaultPrediction.call(actor)
      prediction_results.each do |result|
        create_prediction(actor, result) if should_create_prediction?(result)
      end

      sleep(1) # Rate limit to avoid overwhelming the prediction service
    end
  end

  def should_create_prediction?(prediction_results)
    prediction_results['confidence'] > 0.5
  end

  def create_prediction(threat_actor, prediction_results)
    host = Host.find_by(ip: prediction_results['ip'])

    Prediction.create!(
      host: host,
      threat_actor: threat_actor,
      context: prediction_results['context'],
      confidence: prediction_results['confidence']
    )
  end
end
