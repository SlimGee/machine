# frozen_string_literal: true

class CreateHosts < ActiveRecord::Migration[8.0]
  def change
    create_table :hosts do |t|
      t.string :ip

      t.timestamps
    end
  end
end
