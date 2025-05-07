# frozen_string_literal: true

class AddVectorColumnToAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :assets, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
