class ThreatActor < ApplicationRecord
  has_many :threat_actor_indicators
  has_many :indicators, through: :threat_actor_indicators

  has_many :event_threat_actors
  has_many :events, through: :event_threat_actors
end
