class Setting < ApplicationRecord
  # Set default values
  after_initialize :set_defaults, if: :new_record?
  
  # Validations
  validates :timer, presence: true, numericality: { greater_than: 0 }
  
  private
  
  def set_defaults
    self.auto_start ||= false
    self.timer ||= 60
  end
end
