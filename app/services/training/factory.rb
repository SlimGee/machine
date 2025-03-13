module Training
  class Factory
    def self.for(model_type)
      case model_type.to_s
      when "random_forest"
        Training::RandomForest.new
      when "neural_network"
        Training::NeuralNetwork.new
      when "gradient_boosting"
        Training::GradientBoosting.new
      when "svm"
        Training::SVM.new
      when "ensemble"
        Training::Ensemble.new
      else
        raise ArgumentError, "Unknown model type: #{model_type}"
      end
    end
  end
end
