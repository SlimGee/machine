class Source < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  self::SOURCE_TYPES = %w[txt json csv].freeze
end
