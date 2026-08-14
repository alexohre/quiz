class CreateStageEliminations < ActiveRecord::Migration[7.1]
  def change
    create_table :stage_eliminations do |t|
      t.references :church, null: false, foreign_key: true
      t.references :stage, null: false, foreign_key: true

      t.timestamps
    end
  end
end
