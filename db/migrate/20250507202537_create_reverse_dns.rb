# frozen_string_literal: true

class CreateReverseDns < ActiveRecord::Migration[8.0]
  def change
    create_table :reverse_dns do |t|
      t.datetime :resolved_at
      t.references :dns, null: false, foreign_key: true

      t.timestamps
    end
  end
end
