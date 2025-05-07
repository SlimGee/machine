# frozen_string_literal: true

class Assistant < ActiveRecord::Base
  has_many :messages

  def llm
    Langchain::LLM::MistralAI.new(api_key: Rails.application.credentials.dig(:mistral_ai, :api_key))
  end
end
