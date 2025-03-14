class Target < ApplicationRecord
  has_many :predictions
  has_many :assets

  validates :name, presence: true
  validates :risk_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }, allow_nil: true
end
