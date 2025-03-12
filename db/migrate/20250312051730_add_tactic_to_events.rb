class AddTacticToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :tactic, null: false, foreign_key: true
  end
end
