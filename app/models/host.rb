# frozen_string_literal: true

class Host < ApplicationRecord
  vectorsearch

  after_save -> { CreateModelEmbeddingsJob.perform_later(self) }

  has_one :host_location, dependent: :destroy
  has_one :location, through: :host_location

  has_one :host_autonomous_system, dependent: :destroy
  has_one :autonomous_system, through: :host_autonomous_system

  has_one :host_whois_record, dependent: :destroy
  has_one :whois_record, through: :host_whois_record

  has_one :host_operating_system, dependent: :destroy
  has_one :operating_system, through: :host_operating_system

  has_one :dns, class_name: 'Dn', dependent: :destroy, inverse_of: :host

  has_many :host_vulnerabilities, dependent: :destroy
  has_many :vulnerabilities, through: :host_vulnerabilities

  has_many :services, dependent: :destroy

  def self.embed!
    find_each do |record|
      record.upsert_to_vectorsearch
      # handle rate limiting to mistral ai
      sleep(2)
    end
  end

  def as_vector
    ActiveModelSerializers::SerializableResource.new(self, serializer: HostSerializer).to_json
  end
end
