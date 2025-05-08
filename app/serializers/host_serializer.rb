# frozen_string_literal: true

class HostSerializer < ActiveModel::Serializer
  attributes :id, :ip, :created_at, :updated_at

  has_one :location, through: :host_location

  has_one :autonomous_system, through: :host_autonomous_system

  has_one :whois_record, through: :host_whois_record

  has_one :operating_system, through: :host_operating_system

  has_one :dns, class_name: 'Dn', dependent: :destroy, inverse_of: :host

  has_many :vulnerabilities, through: :host_vulnerabilities

  has_many :services, dependent: :destroy
end
