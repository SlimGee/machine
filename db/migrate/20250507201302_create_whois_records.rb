# frozen_string_literal: true

class CreateWhoisRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :whois_records do |t|
      t.string :network_handle
      t.string :network_name
      t.datetime :network_created
      t.datetime :network_updated
      t.string :network_allocation_type
      t.string :organization_handle
      t.string :organization_name
      t.string :organization_street
      t.string :organization_city
      t.string :organization_state
      t.string :organization_postal_code
      t.string :organization_country
      t.string :abuse_contact_handle
      t.string :abuse_contact_name
      t.string :abuse_contact_email
      t.string :admin_contact_handle
      t.string :admin_contact_name
      t.string :admin_contact_email

      t.timestamps
    end
  end
end
