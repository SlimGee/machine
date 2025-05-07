class Source < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  self::SOURCE_TYPES = %w[txt json csv].freeze

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(5)
    end
  end
end
