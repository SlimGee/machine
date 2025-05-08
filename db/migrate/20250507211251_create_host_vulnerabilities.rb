# frozen_string_literal: true

class CreateHostVulnerabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :host_vulnerabilities do |t|
      t.belongs_to :host, null: false, foreign_key: true
      t.belongs_to :vulnerability, null: false, foreign_key: true

      t.timestamps
    end
  end
end
