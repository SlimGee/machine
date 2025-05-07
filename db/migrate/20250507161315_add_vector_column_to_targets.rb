# frozen_string_literal: true

class AddVectorColumnToTargets < ActiveRecord::Migration[8.0]
  def change
    add_column :targets, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
