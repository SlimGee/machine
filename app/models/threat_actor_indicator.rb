class ThreatActorIndicator < ApplicationRecord
  belongs_to :threat_actor
  belongs_to :indicator
end
