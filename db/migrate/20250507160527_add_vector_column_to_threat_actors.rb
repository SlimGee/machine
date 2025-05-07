# frozen_string_literal: true

class AddVectorColumnToThreatActors < ActiveRecord::Migration[8.0]
  def change
    add_column :threat_actors, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
