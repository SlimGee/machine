class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.timestamp :start_time
      t.timestamp :end_time

      t.timestamps
    end
  end
end
