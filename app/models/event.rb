class Event < ApplicationRecord
  has_many :event_indicators
  has_many :indicators, through: :event_indicators

  has_many :correlations_as_first, class_name: "Correlation", foreign_key: "first_event_id"
  has_many :correlations_as_second, class_name: "Correlation", foreign_key: "second_event_id"

  belongs_to :tactic, optional: true

  has_many :event_threat_actors
  has_many :threat_actors, through: :event_threat_actors

  validates :type, :timestamp, presence: true
  validates :severity, inclusion: { in: %w[low medium high critical] }, allow_nil: true
end
