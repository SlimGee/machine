# frozen_string_literal: true

class CreateAutonomousSystems < ActiveRecord::Migration[8.0]
  def change
    create_table :autonomous_systems do |t|
      t.integer :asn
      t.string :description
      t.string :bgp_prefix
      t.string :name
      t.string :country_code

      t.timestamps
    end
  end
end
