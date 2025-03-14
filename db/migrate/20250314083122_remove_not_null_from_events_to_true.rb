class RemoveNotNullFromEventsToTrue < ActiveRecord::Migration[8.0]
  def change
    change_column_null :events, :tactic_id, true
  end
end
