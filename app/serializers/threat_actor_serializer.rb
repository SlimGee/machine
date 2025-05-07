# frozen_string_literal: true

class ThreatActorSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :first_seen, :last_seen, :confidence, :created_at, :updated_at

  has_many :indicators, through: :threat_actor_indicators

  has_many :events, through: :event_threat_actors

  has_many :malwares, through: :malware_threat_actors
end
