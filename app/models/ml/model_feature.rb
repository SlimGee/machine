class Ml::ModelFeature < ApplicationRecord
  belongs_to :prediction_model, class_name: "Ml::PredictionModel"

  validates :name, :feature_type, presence: true
  validates :name, uniqueness: { scope: :prediction_model_id }

  enum :feature_type, {
    numeric: "numeric",
    categorical: "categorical",
    boolean: "boolean",
    temporal: "temporal"
  }
end
