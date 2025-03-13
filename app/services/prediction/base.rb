module Prediction
  class Base
    def predict(model, features)
      raise NotImplementedError, "#{self.class} must implement #predict"
    end

    protected

      def preprocess_features(features)
        # Normalize/scale features as needed
        processed = features.dup

        # Handle missing values
        processed.each do |key, value|
          processed[key] = 0 if value.nil?
        end

        # Normalize numerical features
        numeric_keys = [ :risk_score, :asset_count, :critical_assets ]
        numeric_keys.each do |key|
          next unless processed.key?(key)
          # Simple min-max scaling
          processed[key] = processed[key].to_f / 100.0 if processed[key].to_f > 1.0
        end

        # Encode categorical features
        if processed[:industry].present?
          # One-hot encoding for industry
          industry_categories = [ "technology", "finance", "healthcare", "government", "manufacturing", "retail", "other" ]
          industry_categories.each do |industry|
            processed["industry_#{industry}"] = (processed[:industry].to_s.downcase == industry) ? 1 : 0
          end
          processed.delete(:industry)
        end

        processed
      end
  end
end
