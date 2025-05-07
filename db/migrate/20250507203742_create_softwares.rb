# frozen_string_literal: true

class CreateSoftwares < ActiveRecord::Migration[8.0]
  def change
    create_table :softwares do |t|
      t.belongs_to :service, null: false, foreign_key: true
      t.string :product
      t.string :vendor
      t.string :version

      t.timestamps
    end
  end
end
