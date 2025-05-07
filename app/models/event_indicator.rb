class EventIndicator < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  belongs_to :event
  belongs_to :indicator

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(1)
    end
  end
end
