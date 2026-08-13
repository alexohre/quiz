class AddBonusPointsToScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :bonus_points, :integer, default: 0
  end
end
