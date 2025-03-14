class Indicator < ApplicationRecord
  belongs_to :source
  has_many :event_indicators
  has_many :events, through: :event_indicators

  validates :type, :value, presence: true
  validates :confidence, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
end
