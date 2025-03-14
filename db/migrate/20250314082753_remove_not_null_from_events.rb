class RemoveNotNullFromEvents < ActiveRecord::Migration[8.0]
  def change
    change_column_null :events, :tactic_id, false
  end
end
