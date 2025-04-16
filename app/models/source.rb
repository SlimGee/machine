class Source < ApplicationRecord
  self::SOURCE_TYPES = %w[txt json csv].freeze
end
