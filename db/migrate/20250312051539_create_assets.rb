class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.belongs_to :target, null: false, foreign_key: true
      t.text :asset_type
      t.string :identifier
      t.integer :criticality

      t.timestamps
    end
  end
end
