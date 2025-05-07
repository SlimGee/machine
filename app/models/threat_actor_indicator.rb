class ThreatActorIndicator < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  belongs_to :threat_actor
  belongs_to :indicator
end
