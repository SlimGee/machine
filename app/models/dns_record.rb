# frozen_string_literal: true

class DnsRecord < ApplicationRecord
  belongs_to :dns, class_name: 'Dn', inverse_of: :dns_records
end
