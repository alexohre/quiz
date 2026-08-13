class Setting < ApplicationRecord
  after_initialize :set_defaults, if: :new_record?
  
  validates :timer, presence: true, numericality: { greater_than: 0 }
  validates :points_per_question, presence: true, numericality: { greater_than: 0 }
  
  private
  
  def set_defaults
    self.auto_start ||= false
    self.timer ||= 60
    self.points_per_question ||= 10
  end
end
