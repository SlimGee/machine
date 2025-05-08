class CreatePredictionsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :predictions do |t|
      t.timestamps
      t.belongs_to :threat_actor, null: false, foreign_key: true
      t.belongs_to :host, null: false, foreign_key: true
      t.text :context
      t.decimal :confidence, precision: 5, scale: 2
      t.vector :embedding, limit: LangchainrbRails.config.vectorsearch.llm.default_dimensions
    end
  end
end
