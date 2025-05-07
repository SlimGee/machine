# frozen_string_literal: true

class AddVectorColumnToSources < ActiveRecord::Migration[8.0]
  def change
    add_column :sources, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
