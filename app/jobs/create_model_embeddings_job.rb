class CreateModelEmbeddingsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :create_model_embeddings_job

  def perform(model)
    model.upsert_to_vectorsearch
  end
end
