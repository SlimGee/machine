class AnalysisJob < ApplicationJob
  queue_as :analysis

  def perform
    Rails.logger.info("Starting autonomous analysis")

    Analysis::Engine.analyze_new_indicators
  end
end
