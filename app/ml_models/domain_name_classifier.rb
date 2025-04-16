class DomainNameClassifier < Eps::Base
  def build
  end

  def predict(domain_name)
    begin
      label_encoders = JSON.parse(File.read(File.join(__dir__, "inference/label_encoders.json")))
    rescue StandardError => e
      puts "Error loading label encoders: #{e}"
      return nil
    end
    # Extract and encode features
    features = extract_features(domain_name, label_encoders)

    # Predict
    prediction = model.predict(features)

    # Extract probabilities and class
    class_names = label_encoders["label"].keys
    probs = class_names.map { |cls| [ cls, prediction["probability(#{label_encoders['label'][cls]})"] || 0.0 ] }
    pred_class = probs.max_by { |_, prob| prob }[0]

    # Output results
    puts "\nDomain: #{domain_name}"
    puts "Predicted Class: #{pred_class}"
    puts "Class Probabilities:"
    probs.each { |cls, prob| puts "  #{cls}: #{prob.round(4)}" }

    [ pred_class, probs.to_h ]
  end

  private

    def features(domain_name)
    end

    def model
      @model ||= Eps::Model.load_pmml(File.read(model_file))
    end

    def model_file
      File.join(__dir__, "inference/domain_name_classifier.pmml")
    end

    # Function to calculate entropy of a string
    def calculate_entropy(str)
      return 0.0 if str.empty?
      freq = str.chars.tally
      len = str.length.to_f
      freq.values.sum { |count| prob = count / len; prob > 0 ? -prob * Math.log2(prob) : 0 }
    end

    # Function to extract n-grams from a string
    def extract_ngrams(str, n)
      str.downcase.chars.each_cons(n).map(&:join)
    end

    # Function to encode categorical feature using label encoder mappings
    def encode_categorical(value, encoder, default = "missing")
      value = value.to_s
      encoder[value] || encoder[default] || 0
    end

    # Function to extract features from a domain name
    def extract_features(domain, label_encoders)
      domain = domain.to_s.downcase.strip
      domain = domain.gsub(/^(b['"])|['"]$/, "") # Remove byte string prefix/suffix

      features = {}

      # Numeric features
      features["entropy"] = calculate_entropy(domain)
      features["numeric_percentage"] = domain.chars.count { |c| c.match?(/\d/) } / domain.length.to_f
      features["len"] = domain.length
      features["subdomain"] = domain.split(".").length > 2 ? 1 : 0

      begin
        # Check for punycode
        decoded = IDN::Idna.toUnicode(domain)
        features["puny_coded"] = decoded != domain ? 1 : 0
      rescue
        features["puny_coded"] = 0
      end

      # Default numeric features (not derivable from domain)
      %w[ASN TTL Name_Server_Count Domain_Age hex_8 dec_8 dec_32 shortened oc_8 hex_32
         Page_Rank oc_32 Alexa_Rank obfuscate_at_sign Emails].each do |f|
        features[f] = 0
      end

      # Categorical features
      features["tld"] = domain.split(".").last || ""
      words = domain.scan(/[a-z]+/)
      features["longest_word"] = words.max_by(&:length) || ""
      features["sld"] = domain.split(".").first || domain
      %w[Country Organization Country.1 Registrant_Name State Registrar].each do |f|
        features[f] = "missing"
      end

      # Complex features
      features["1gram_count"] = extract_ngrams(domain, 1).length
      features["2gram_count"] = extract_ngrams(domain, 2).length
      features["3gram_count"] = extract_ngrams(domain, 3).length
      features["typos_count"] = 0 # Placeholder
      char_dist = domain.chars.tally
      features["char_distribution_sum"] = char_dist.values.sum

      # Special features
      features["IP_sum"] = 0
      features["days_since_creation"] = nil # Missing value

      # Encode categorical features
      encoded_features = features.dup
      %w[Country tld Organization Country.1 longest_word Registrant_Name sld State Registrar].each do |f|
        encoded_features[f] = encode_categorical(features[f], label_encoders[f] || {})
      end

      # Handle missing values (replace nil with mean, assumed 0 for simplicity)
      encoded_features.transform_values { |v| v.nil? ? 0 : v }
    end
end
