class ThreatActor < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  has_many :threat_actor_indicators
  has_many :indicators, through: :threat_actor_indicators

  has_many :event_threat_actors
  has_many :events, through: :event_threat_actors

  has_many :malware_threat_actors, dependent: :destroy
  has_many :malwares, through: :malware_threat_actors
end
