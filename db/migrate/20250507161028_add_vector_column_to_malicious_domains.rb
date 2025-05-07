# frozen_string_literal: true

class AddVectorColumnToMaliciousDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :malicious_domains, :embedding, :vector,
               limit: LangchainrbRails
                 .config
                 .vectorsearch
                 .llm
                 .default_dimensions
  end
end
