# frozen_string_literal: true

class WhoisRecord < ApplicationRecord
  has_many :host_whois_records, dependent: :destroy
  has_many :hosts, through: :host_whois_records

  has_many :network_cidrs, dependent: :destroy
end
