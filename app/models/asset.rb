class Asset < ApplicationRecord
  vectorsearch

  belongs_to :target
  has_many :vulnerabilities

  validates :type, :identifier, presence: true
  validates :criticality, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10 },
                          allow_nil: true
end
