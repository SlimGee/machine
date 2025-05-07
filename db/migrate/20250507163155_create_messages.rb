# frozen_string_literal: true

class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :assistant, foreign_key: true
      t.string :role
      t.text :content
      t.json :tool_calls
      t.string :tool_call_id
      t.timestamps
    end
  end
end
