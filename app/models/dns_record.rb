# frozen_string_literal: true

class DnsRecord < ApplicationRecord
  belongs_to :dns, class_name: 'Dn'
end
