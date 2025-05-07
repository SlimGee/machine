# frozen_string_literal: true

class CreateNetworkCidrs < ActiveRecord::Migration[8.0]
  def change
    create_table :network_cidrs do |t|
      t.string :cidr
      t.belongs_to :whois_record, null: false, foreign_key: true

      t.timestamps
    end
  end
end
