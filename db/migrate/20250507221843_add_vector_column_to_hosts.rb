# frozen_string_literal: true

class AddVectorColumnToHosts < ActiveRecord::Migration[8.0]
  def change
    add_column :hosts, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
