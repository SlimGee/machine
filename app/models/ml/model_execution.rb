class Ml::ModelExecution < ApplicationRecord
  belongs_to :prediction_model, class_name: "Ml::PredictionModel"
  belongs_to :target

  validates :executed_at, presence: true
  validates :input_features, :result, presence: true

  serialize :input_features, JSON
  serialize :result, JSON
end
