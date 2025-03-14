module Predict
  class Factory
    def self.for(model_type)
      case model_type.to_s
      when "random_forest"
        Prediction::RandomForest.new
      when "neural_network"
        Prediction::NeuralNetwork.new
      when "gradient_boosting"
        Prediction::GradientBoosting.new
      when "svm"
        Prediction::SVM.new
      when "ensemble"
        Prediction::Ensemble.new
      else
        raise ArgumentError, "Unknown model type: #{model_type}"
      end
    end
  end
end
