# frozen_string_literal: true

class AddVectorColumnToEventThreatActors < ActiveRecord::Migration[8.0]
  def change
    add_column :event_threat_actors, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
