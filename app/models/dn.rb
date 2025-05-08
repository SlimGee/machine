# frozen_string_literal: true

class Dn < ApplicationRecord
  belongs_to :host
  has_many :dns_records, dependent: :destroy, foreign_key: :dns_id, inverse_of: :dns
end
