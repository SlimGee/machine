class Reporting::ThreatIntelligenceReport
  PROMPT = <<~PROMPT
    Given the following threat intelligence data, identify the most relevant information and provide a comprehensive threat intelligence report.
    Your report should provide insights into the threat landscape, including trends, patterns, and anomalies.generate

    These are not our systems, we just provide a holistic view of the threat landscape.
    use markdown formatting and make the report is comprehensive and extensive
    here is the context:
    {context}
    Simply return the body of the report, do not include any other text, metadata or commentary and DO NOT explain what you're doing
  PROMPT

  FINE_TUNE = <<~PROMPT
    You are a threat intelligence analyst AI model.
    You are capable of finding the most relevant information from a set of threat intelligence data.
    You are skilled in pattern recognition and can identify trends and anomalies in the data.
    You are automous and operate without human intervention.
  PROMPT

  def generate(from = Time.now - 14.day, to = Time.now)
    messages = [
      { role: "model", parts: [ { text: FINE_TUNE } ] },
      { role: "user", parts: [ { text: prompt(from, to) } ] }
    ]

    gemini_llm = Langchain::LLM::GoogleGemini.new(api_key: Rails.application.credentials.dig(:gemini, :api_key))
    response = gemini_llm.chat(messages: messages, model: "gemini-2.5-flash-preview-04-17").chat_completion

    puts response.inspect


    Report.create(
      content: Kramdown::Document.new(response).to_html,
      start_time: from,
      end_time: to,
    )

  rescue StandardError => e
    puts e.inspect
  end

  def output_parser
    json_schema = {
      type: "object",
      properties: {
        content: {
          type: "string",
          description: "The full body of the report"
        }
      }
    }

    Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)
  end

  def get_ouput(response, parser, llm)
    begin
      parser.parse(response)
    rescue Langchain::OutputParsers::OutputParserException => e
      fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
        llm: llm,
        parser: parser
      )
      fix_parser.parse(response)
    end
  end

  def self.generate(from = Time.now - 14.day, to = Time.now)
    new.generate(from, to)
  end

  def self.call(from = Time.now - 14.day, to = Time.now)
    new.generate(from, to)
  end


  def prompt(from, to)
    prompt = Langchain::Prompt::PromptTemplate.new(template: PROMPT, input_variables: [ "context" ])

    hosts = Host.where("created_at >= ? AND created_at <= ?", from, to).limit(1000)
    hosts_data = "Hosts:\n"
    hosts_data += hosts.map(&:as_vector).join("\n")

    threat_actors = ThreatActor.where("created_at >= ? AND created_at <= ?", from, to).limit(1000)
    threat_actors_data = "\nThreat Actors:\n"
    threat_actors_data += threat_actors.map(&:as_vector).join("\n")

    indicators = Indicator.where("created_at >= ? AND created_at <= ?", from, to).order(created_at: :desc).limit(500)
    indicators_data = "\nIndicators of Compromise:\n"
    indicators_data += indicators.map(&:as_vector).join("\n")

    predictions = Prediction.where("created_at >= ? AND created_at <= ?", from, to).limit(1000)
    predictions_data = "\nPredictions:\n"
    predictions_data += predictions.map(&:as_vector).join("\n")

    malware = Malware.where("created_at >= ? AND created_at <= ?", from, to).limit(1000)
    malware_data = "\nMalware:\n"
    malware_data += malware.map(&:as_vector).join("\n")

    context = hosts_data + threat_actors_data + indicators_data + predictions_data + malware_data

    prompt.format(context: context)
  end
end
