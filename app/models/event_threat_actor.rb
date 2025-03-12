class EventThreatActor < ApplicationRecord
  belongs_to :event
  belongs_to :threat_actor
end
