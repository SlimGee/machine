# frozen_string_literal: true

LangchainrbRails.configure do |config|
  config.vectorsearch = Langchain::Vectorsearch::Pgvector.new(
    llm: Langchain::LLM::MistralAI.new(api_key: Rails.application.credentials.dig(:mistral_ai, :api_key))
  )
end
