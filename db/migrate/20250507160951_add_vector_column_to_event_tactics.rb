# frozen_string_literal: true

class AddVectorColumnToEventTactics < ActiveRecord::Migration[8.0]
  def change
    add_column :event_tactics, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
