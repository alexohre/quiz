class Church < ApplicationRecord
  validates :name, presence: true
  has_many :representatives, dependent: :destroy
  has_many :scores, dependent: :destroy

  def total_score
    scores.sum("points + COALESCE(bonus_points, 0)")
  end

  def score_for_stage(stage)
    scores.where(stage: stage).sum("points + COALESCE(bonus_points, 0)")
  end

  def score_for_stage_and_round(stage, round_num)
    sc = scores.find_by(stage: stage, round_number: round_num)
    sc ? sc.total_stage_points : 0
  end

  def base_points_for_stage_and_round(stage, round_num)
    scores.find_by(stage: stage, round_number: round_num)&.points || 0
  end

  def bonus_points_for_stage_and_round(stage, round_num)
    scores.find_by(stage: stage, round_number: round_num)&.bonus_points || 0
  end
end
