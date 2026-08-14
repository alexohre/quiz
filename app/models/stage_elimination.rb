class StageElimination < ApplicationRecord
  belongs_to :church
  belongs_to :stage

  validates :church_id, uniqueness: { scope: :stage_id }
end
