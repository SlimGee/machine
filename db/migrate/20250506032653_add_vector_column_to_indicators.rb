# frozen_string_literal: true

class AddVectorColumnToIndicators < ActiveRecord::Migration[8.0]
  def change
    add_column :indicators, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
