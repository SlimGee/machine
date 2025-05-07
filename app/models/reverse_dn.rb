# frozen_string_literal: true

class ReverseDn < ApplicationRecord
  belongs_to :dns, class_name: 'Dn'
end
