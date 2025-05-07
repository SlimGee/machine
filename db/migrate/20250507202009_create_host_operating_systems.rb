# frozen_string_literal: true

class CreateHostOperatingSystems < ActiveRecord::Migration[8.0]
  def change
    create_table :host_operating_systems do |t|
      t.belongs_to :operating_system, null: false, foreign_key: true
      t.belongs_to :host, null: false, foreign_key: true

      t.timestamps
    end
  end
end
