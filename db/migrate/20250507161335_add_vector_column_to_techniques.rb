# frozen_string_literal: true

class AddVectorColumnToTechniques < ActiveRecord::Migration[8.0]
  def change
    add_column :techniques, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
