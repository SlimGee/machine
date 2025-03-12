class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :event_type
      t.timestamp :timestamp
      t.text :description
      t.string :severity

      t.timestamps
    end
  end
end
