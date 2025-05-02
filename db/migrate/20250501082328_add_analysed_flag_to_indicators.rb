class AddAnalysedFlagToIndicators < ActiveRecord::Migration[8.0]
  def change
    add_column :indicators, :analysed, :boolean, default: false,  null: false
  end
end
