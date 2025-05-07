# frozen_string_literal: true

class CreateOperatingSystems < ActiveRecord::Migration[8.0]
  def change
    create_table :operating_systems do |t|
      t.string :uniform_resource_identifier
      t.string :part
      t.string :vendor
      t.string :product
      t.string :family

      t.timestamps
    end
  end
end
