# frozen_string_literal: true

class AddVectorColumnToEventIndicators < ActiveRecord::Migration[8.0]
  def change
    add_column :event_indicators, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
