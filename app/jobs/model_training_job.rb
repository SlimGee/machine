class ModelTrainingJob < ApplicationJob
  queue_as :machine_learning

  def perform(model)
    Rails.logger.info("Starting training for model: #{model.name}")

    begin
      result = model.train!

      if result
        Rails.logger.info("Model #{model.name} trained successfully")
      else
        Rails.logger.error("Model #{model.name} training failed")
      end
    rescue => e
      Rails.logger.error("Error training model #{model.name}: #{e.message}")
      model.update(status: :failed)
    end
  end
end
