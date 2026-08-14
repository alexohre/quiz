class Church < ApplicationRecord
  validates :name, presence: true
  has_many :representatives, dependent: :destroy
  has_many :scores, dependent: :destroy
  has_many :stage_eliminations, dependent: :destroy

  def eliminated_in_stage?(stage)
    return false if stage.blank?
    stg_id = stage.is_a?(Stage) ? stage.id : stage.to_i
    stage_eliminations.exists?(stage_id: stg_id)
  end

  def active_in_stage?(stage)
    !eliminated_in_stage?(stage)
  end

  scope :active_in_stage, ->(stage) {
    return all if stage.blank?
    stg_id = stage.is_a?(Stage) ? stage.id : stage.to_i
    where.not(id: StageElimination.where(stage_id: stg_id).select(:church_id))
  }

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
