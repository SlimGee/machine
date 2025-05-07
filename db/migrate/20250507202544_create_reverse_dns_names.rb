# frozen_string_literal: true

class CreateReverseDnsNames < ActiveRecord::Migration[8.0]
  def change
    create_table :reverse_dns_names do |t|
      t.string :name
      t.references :reverse_dns, null: false, foreign_key: true

      t.timestamps
    end
  end
end
