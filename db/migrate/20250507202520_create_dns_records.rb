# frozen_string_literal: true

class CreateDnsRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :dns_records do |t|
      t.string :domain
      t.string :record_type
      t.datetime :resolved_at
      t.references :dns, null: false, foreign_key: true

      t.timestamps
    end
  end
end
