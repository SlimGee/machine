# frozen_string_literal: true

class ReverseDnsName < ApplicationRecord
  belongs_to :reverse_dns, class_name: 'ReverseDn'
end
