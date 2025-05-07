# frozen_string_literal: true

class HostOperatingSystem < ApplicationRecord
  belongs_to :operating_system
  belongs_to :host
end
