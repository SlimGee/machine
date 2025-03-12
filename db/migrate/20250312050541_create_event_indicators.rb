class CreateEventIndicators < ActiveRecord::Migration[8.0]
  def change
    create_table :event_indicators do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :indicator, null: false, foreign_key: true
      t.text :context

      t.timestamps
    end
  end
end
