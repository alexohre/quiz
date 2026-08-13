class CreateScores < ActiveRecord::Migration[7.1]
  def change
    create_table :scores do |t|
      t.references :church, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true
      t.integer :points

      t.timestamps
    end
  end
end
