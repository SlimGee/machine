class CreateEventTactics < ActiveRecord::Migration[8.0]
  def change
    create_table :event_tactics do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :tactic, null: false, foreign_key: true

      t.timestamps
    end
  end
end
