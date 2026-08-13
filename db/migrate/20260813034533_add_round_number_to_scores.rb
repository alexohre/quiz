class AddRoundNumberToScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :round_number, :integer, default: 1
  end
end
