class Predict::DefaultPrediction < Predict::Base
  def predict(threat_actor)
    json_schema = {
      type: 'object',
      properties: {
        targets: {
          tpe: 'array',
          items: {
            type: 'object',
            properties: {
              ip: { type: 'string' },
              context: { type: 'string' },
              confidence: {
                type: 'number',
                description: 'Confidence score of the prediction, between 0 and 1. should reflect the certainty of the prediction. should below 0.5 if exploitability is low',
              },
            },
          },
        },
      },
    }

    parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)
    prompt = Langchain::Prompt::PromptTemplate.new(
      template: "You're the machine from person of interest but you analyse cyber threats. You're an automomous system without human supervision capable of making highly logical decisions. Your main directive and goal is provide proactive cyber threat intelligence.\n{format_instructions}\n find potential targets for this threat actor:{threat_actor}", input_variables: [
        'threat_actor', 'format_instructions',
      ],
    )

    prompt_text = prompt.format(
      threat_actor: threat_actor.as_vector,
      format_instructions: parser.get_format_instructions,
    )

    llm_response = Host.ask(prompt_text)

    parser.parse(llm_response)
  end
end
