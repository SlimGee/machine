class Tactic < ApplicationRecord
  vectorsearch

  has_many :event_tactics
  has_many :events, through: :event_tactics

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(1)
    end
  end
end
