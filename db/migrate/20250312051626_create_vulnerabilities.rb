class CreateVulnerabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :vulnerabilities do |t|
      t.belongs_to :asset, null: false, foreign_key: true
      t.text :cve_id
      t.text :description
      t.float :cvss_score
      t.boolean :exploitable, null: false, default: false

      t.timestamps
    end
  end
end
