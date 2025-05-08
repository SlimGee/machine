class ThreatActor < ApplicationRecord
  vectorsearch

  has_many :threat_actor_indicators
  has_many :indicators, through: :threat_actor_indicators

  has_many :event_threat_actors
  has_many :events, through: :event_threat_actors

  has_many :malware_threat_actors, dependent: :destroy
  has_many :malwares, through: :malware_threat_actors

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(1)
    end
  end

  def as_vector
    ActiveModelSerializers::SerializableResource.new(self, serializer: ThreatActorSerializer).to_json
  end
end
