# frozen_string_literal: true

class CreateDnsNames < ActiveRecord::Migration[8.0]
  def change
    create_table :dns_names do |t|
      t.string :name
      t.belongs_to :dns, null: false, foreign_key: true

      t.timestamps
    end
  end
end
