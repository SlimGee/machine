class AnalysisJob < ApplicationJob
  queue_as :analysis

  def perform
    Rails.logger.info("Starting autonomous analysis")

    # Run the autonomous analyzer
    Analysis::Engine.analyze_new_indicators

    # Update prediction models if needed
    # if should_update_models?
    ##  Ml::PredictionModel.where(status: :active).each do |model|
    #    ModelTrainingJob.perform_later(model)
    #  end
    # end

    # Run predictions for high-risk targets
    predict_for_high_risk_targets
  end

  private
    def should_update_models?
      # Check if models need updating (e.g., no updates in past week)
      Ml::PredictionModel.where(status: :active)
                                     .where("last_trained_at < ?", 1.week.ago)
                                     .exists?
    end

    def predict_for_high_risk_targets
      # Select high-risk targets for prediction updates
      high_risk_targets = Target.where("risk_score > ?", 0.7)
                               .order(risk_score: :desc)
                               .limit(10)

      # Default to active models
      models = Ml::PredictionModel.where(status: :active)

      # Run predictions for each target
      high_risk_targets.each do |target|
        TargetPredictionJob.perform_later(target, models.pluck(:id))
      end
    end
end
