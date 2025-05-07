# frozen_string_literal: true

class CreateHostWhoisRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :host_whois_records do |t|
      t.belongs_to :host, null: false, foreign_key: true
      t.belongs_to :whois_record, null: false, foreign_key: true

      t.timestamps
    end
  end
end
