class MaliciousDomain < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(5)
    end
  end
end
