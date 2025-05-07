# frozen_string_literal: true

class CreateDns < ActiveRecord::Migration[8.0]
  def change
    create_table :dns do |t|
      t.belongs_to :host, null: false, foreign_key: true

      t.timestamps
    end
  end
end
