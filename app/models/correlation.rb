class Correlation < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  belongs_to :first_event, class_name: "Event"
  belongs_to :second_event, class_name: "Event"
end
