# frozen_string_literal: true

class AutonomousSystem < ApplicationRecord
  has_many :host_autonomous_systems, dependent: :destroy
  has_many :hosts, through: :host_autonomous_systems
end
