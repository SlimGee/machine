class CreatePredictions < ActiveRecord::Migration[8.0]
  def change
    create_table :predictions do |t|
      t.belongs_to :threat_actor, null: false, foreign_key: true
      t.belongs_to :target, null: false, foreign_key: true
      t.belongs_to :technique, null: false, foreign_key: true
      t.float :confidence
      t.datetime :estimated_timeframe
      t.datetime :predictioni_date

      t.timestamps
    end
  end
end
