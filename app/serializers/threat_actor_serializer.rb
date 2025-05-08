# frozen_string_literal: true

class ThreatActorSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :first_seen, :last_seen, :confidence, :created_at, :updated_at

  has_many :indicators, through: :threat_actor_indicators do
    object.indicators.last(20)
  end

  has_many :events, through: :event_threat_actors do
    object.events.last(20)
  end

  has_many :malwares, through: :malware_threat_actors
end
