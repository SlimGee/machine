class Report < ApplicationRecord
  has_rich_text :content

  validates :start_time, presence: true
  validates :end_time, presence: true

  after_initialize :set_default_attributes

  private

  def set_default_attributes
    self.start_time = Time.zone.today - 14.days if start_time.blank?
    self.end_time = Time.zone.today if end_time.blank?
  end
end
