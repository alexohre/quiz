class RenameStagesIdToStageIdInQuizzes < ActiveRecord::Migration[7.1]
  def change
    rename_column :quizzes, :stages_id, :stage_id
  end
end
