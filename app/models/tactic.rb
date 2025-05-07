class Tactic < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  has_many :event_tactics
  has_many :events, through: :event_tactics
end
