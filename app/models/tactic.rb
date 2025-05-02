class Tactic < ApplicationRecord
  has_many :event_tactics
  has_many :events, through: :event_tactics
end
