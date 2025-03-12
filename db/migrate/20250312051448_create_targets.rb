class CreateTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :targets do |t|
      t.string :name
      t.string :industry
      t.float :risk_score

      t.timestamps
    end
  end
end
