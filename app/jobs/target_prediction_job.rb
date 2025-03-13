class TargetPredictionJob < ApplicationJob
  queue_as :predictions

  def perform(target, model_ids)
    Rails.logger.info("Running predictions for target: #{target.name}")

    models = Ml::PredictionModel.where(id: model_ids, status: :active)

    # Run prediction with each model
    prediction_results = models.map do |model|
      begin
        model.predict(target)
      rescue => e
        Rails.logger.error("Error predicting with model #{model.name}: #{e.message}")
        nil
      end
    end.compact

    # Create prediction if warranted
    if prediction_results.present? && Analysis::Engine.should_create_prediction?(prediction_results)
      Analysis::Engine.create_prediction(target, prediction_results)
    end
  end
end
