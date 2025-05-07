class Target < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  has_many :predictions
  has_many :assets

  validates :name, presence: true
  validates :risk_score, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 10.0 }, allow_nil: true

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(5)
    end
  end
end
