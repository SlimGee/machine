# frozen_string_literal: true

class Location < ApplicationRecord
  has_many :host_locations, dependent: :destroy
  has_many :hosts, through: :host_locations
end
