# frozen_string_literal: true

class HostWhoisRecord < ApplicationRecord
  belongs_to :host
  belongs_to :whois_record
end
