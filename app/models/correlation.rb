class Correlation < ApplicationRecord
  vectorsearch

  after_save -> { CreateModelEmbeddingsJob.perform_later(self) }

  belongs_to :first_event, class_name: 'Event'
  belongs_to :second_event, class_name: 'Event'

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(5)
    end
  end
end
