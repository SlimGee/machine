class MaliciousDomain < ApplicationRecord
  vectorsearch

  after_save :upsert_to_vectorsearch

end
