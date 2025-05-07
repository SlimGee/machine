# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.text :banner
      t.text :banner_hashes
      t.text :banner_hex
      t.text :extended_service_name
      t.integer :port
      t.string :name
      t.belongs_to :host, null: false, foreign_key: true

      t.timestamps
    end
  end
end
