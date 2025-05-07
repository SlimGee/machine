# frozen_string_literal: true

class HostAutonomousSystem < ApplicationRecord
  belongs_to :autonomous_system
  belongs_to :host
end
