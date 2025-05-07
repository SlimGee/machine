# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :continent
      t.string :country
      t.string :country_code
      t.string :city
      t.string :postal_code
      t.string :timezone
      t.string :province
      t.decimal :latitude
      t.decimal :longitude

      t.timestamps
    end
  end
end
