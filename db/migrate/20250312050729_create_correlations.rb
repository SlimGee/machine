class CreateCorrelations < ActiveRecord::Migration[8.0]
  def change
    create_table :correlations do |t|
      t.references :first_event, null: false, foreign_key: { to_table: :events }
      t.references :second_event, null: false, foreign_key: { to_table: :events }
      t.float :confidence
      t.text :relationship_type
      t.datetime :discovered_at

      t.timestamps
    end
  end
end
