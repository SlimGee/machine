class EventIndicator < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  belongs_to :event
  belongs_to :indicator
end
