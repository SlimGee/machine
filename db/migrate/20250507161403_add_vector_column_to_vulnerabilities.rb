# frozen_string_literal: true

class AddVectorColumnToVulnerabilities < ActiveRecord::Migration[8.0]
  def change
    add_column :vulnerabilities, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
