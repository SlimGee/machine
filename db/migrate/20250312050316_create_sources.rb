class CreateSources < ActiveRecord::Migration[8.0]
  def change
    create_table :sources do |t|
      t.string :name
      t.string :source_type
      t.text :url
      t.integer :reliability
      t.datetime :last_update

      t.timestamps
    end
  end
end
