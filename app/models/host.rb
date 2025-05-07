# frozen_string_literal: true

class Host < ApplicationRecord
  has_one :host_location, dependent: :destroy
  has_one :location, through: :host_location

  has_one :host_autonomous_system, dependent: :destroy
  has_one :autonomous_system, through: :host_autonomous_system

  has_one :host_whois_record, dependent: :destroy
  has_one :whois_record, through: :host_whois_record

  has_one :host_operating_system, dependent: :destroy
  has_one :operating_system, through: :host_operating_system

  has_one :dns, class_name: 'Dn', dependent: :destroy
end
