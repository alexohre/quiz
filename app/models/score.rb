class Score < ApplicationRecord
  belongs_to :church
  belongs_to :stage

  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bonus_points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :round_number, presence: true, numericality: { greater_than: 0 }

  def total_stage_points
    (points || 0) + (bonus_points || 0)
  end
end
