# frozen_string_literal: true

class OperatingSystem < ApplicationRecord
  has_many :host_operting_systems, dependent: :destroy
  has_many :hosts, through: :host_operting_systems
end
