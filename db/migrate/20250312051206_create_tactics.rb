class CreateTactics < ActiveRecord::Migration[8.0]
  def change
    create_table :tactics do |t|
      t.text :mitre_id
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
