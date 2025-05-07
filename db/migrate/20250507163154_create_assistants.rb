# frozen_string_literal: true

class CreateAssistants < ActiveRecord::Migration[8.0]
  def change
    create_table :assistants do |t|
      t.string :instructions
      t.string :tool_choice
      t.json :tools
      t.timestamps
    end
  end
end
