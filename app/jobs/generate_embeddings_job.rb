# frozen_string_literal: true

class GenerateEmbeddingsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    ApplicationRecord.descendants.each do |model|
      model.embed! if model.class_variables.include? :@@provider
      sleep 1.minute
    end
  end
end
