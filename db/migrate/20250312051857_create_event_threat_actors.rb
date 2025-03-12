class CreateEventThreatActors < ActiveRecord::Migration[8.0]
  def change
    create_table :event_threat_actors do |t|
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :threat_actor, null: false, foreign_key: true
      t.float :confidence

      t.timestamps
    end
  end
end
