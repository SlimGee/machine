# frozen_string_literal: true

class AddVectorColumnToCorrelations < ActiveRecord::Migration[8.0]
  def change
    add_column :correlations, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
