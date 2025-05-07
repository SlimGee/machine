# frozen_string_literal: true

class AddVectorColumnToPredictions < ActiveRecord::Migration[8.0]
  def change
    add_column :predictions, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
