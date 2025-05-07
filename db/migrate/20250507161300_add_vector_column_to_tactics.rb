# frozen_string_literal: true

class AddVectorColumnToTactics < ActiveRecord::Migration[8.0]
  def change
    add_column :tactics, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
