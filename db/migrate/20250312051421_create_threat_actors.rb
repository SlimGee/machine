class CreateThreatActors < ActiveRecord::Migration[8.0]
  def change
    create_table :threat_actors do |t|
      t.text :name
      t.text :description
      t.datetime :first_seen
      t.datetime :last_seen
      t.integer :confidence

      t.timestamps
    end
  end
end
