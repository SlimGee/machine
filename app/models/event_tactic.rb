class EventTactic < ApplicationRecord
  vectorsearch

  belongs_to :event
  belongs_to :tactic

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(1)
    end
  end
end
