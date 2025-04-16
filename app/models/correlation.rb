class Correlation < ApplicationRecord
  belongs_to :first_event, class_name: "Event"
  belongs_to :second_event, class_name: "Event"
end
