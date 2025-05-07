# frozen_string_literal: true

class IndicatorSerializer < ActiveModel::Serializer
  attributes :id, :indicator_type, :value, :confidence, :first_seen, :last_seen, :source_id, :created_at, :updated_at,
             :analysed

  has_many :events, through: :event_indicators

  has_many :threat_actors, through: :threat_actor_indicators

  has_many :malwares, through: :malware_indicators
end
