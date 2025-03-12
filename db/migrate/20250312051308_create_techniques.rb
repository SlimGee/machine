class CreateTechniques < ActiveRecord::Migration[8.0]
  def change
    create_table :techniques do |t|
      t.text :mitre_id
      t.string :name
      t.text :description
      t.belongs_to :tactic, null: false, foreign_key: true

      t.timestamps
    end
    add_index :techniques, :mitre_id, unique: true
  end
end
