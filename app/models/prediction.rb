class Prediction < ApplicationRecord
  belongs_to :threat_actor
  belongs_to :target
  belongs_to :technique
end
