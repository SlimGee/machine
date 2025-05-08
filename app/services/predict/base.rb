class Predict::Base
  def predict(threat_actor)
    raise NotImplementedError, "#{self.class} must implement #predict"
  end

  def self.call(threat_actor)
    new.predict(threat_actor)
  end
end
