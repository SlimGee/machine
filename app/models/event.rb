class Event < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  has_many :event_indicators, dependent: :destroy
  has_many :indicators, through: :event_indicators

  has_many :correlations_as_first, class_name: "Correlation", foreign_key: "first_event_id", dependent: :destroy
  has_many :correlations_as_second, class_name: "Correlation", foreign_key: "second_event_id", dependent: :destroy

  has_many :event_threat_actors, dependent: :destroy
  has_many :threat_actors, through: :event_threat_actors, dependent: :destroy

  has_many :event_tactics
  has_many :tactics, through: :event_tactics, dependent: :destroy


  validates :event_type, :timestamp, presence: true
  validates :severity, inclusion: { in: %w[low medium high critical] }, allow_nil: true
end
