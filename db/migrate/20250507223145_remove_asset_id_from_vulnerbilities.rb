# frozen_string_literal: true

class RemoveAssetIdFromVulnerbilities < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :vulnerabilities, :assets
    remove_column :vulnerabilities, :asset_id, :bigint
  end
end
