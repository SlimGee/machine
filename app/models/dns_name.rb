# frozen_string_literal: true

class DnsName < ApplicationRecord
  belongs_to :dns, class_name: 'Dn', inverse_of: :dns_names
end
