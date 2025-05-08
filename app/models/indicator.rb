class Indicator < ApplicationRecord
  vectorsearch

  after_save -> { CreateModelEmbeddingsJob.perform_later(self) }

  belongs_to :source
  has_many :event_indicators, dependent: :destroy
  has_many :events, through: :event_indicators

  has_many :threat_actor_indicators, dependent: :destroy
  has_many :threat_actors, through: :threat_actor_indicators

  has_many :malware_indicators, dependent: :destroy
  has_many :malwares, through: :malware_indicators

  validates :indicator_type, :value, presence: true
  validates :confidence, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
                         allow_nil: true

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(1)
    end
  end

  def as_vector
    ActiveModelSerializers::SerializableResource.new(self, serializer: IndicatorSerializer).to_json
  end
end
