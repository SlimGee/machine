class Correlation < ApplicationRecord
  belongs_to :first_event
  belongs_to :second_event
end
