class CreateThreatActorIndicators < ActiveRecord::Migration[8.0]
  def change
    create_table :threat_actor_indicators do |t|
      t.belongs_to :threat_actor, null: false, foreign_key: true
      t.belongs_to :indicator, null: false, foreign_key: true

      t.timestamps
    end
  end
end
