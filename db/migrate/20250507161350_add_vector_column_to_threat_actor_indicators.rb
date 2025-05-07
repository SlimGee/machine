# frozen_string_literal: true

class AddVectorColumnToThreatActorIndicators < ActiveRecord::Migration[8.0]
  def change
    add_column :threat_actor_indicators, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
