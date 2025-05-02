class EventTactic < ApplicationRecord
  belongs_to :event
  belongs_to :tactic
end
