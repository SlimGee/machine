# frozen_string_literal: true

class EnableVectorExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'vector'
  end
end
