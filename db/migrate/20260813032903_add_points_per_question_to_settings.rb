class AddPointsPerQuestionToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :points_per_question, :integer, default: 10
  end
end
