class CreateIndicators < ActiveRecord::Migration[8.0]
  def change
    create_table :indicators do |t|
      t.string :indicator_type
      t.text :value
      t.integer :confidence
      t.datetime :first_seen
      t.datetime :last_seen
      t.belongs_to :source, null: false, foreign_key: true

      t.timestamps
    end
  end
end
