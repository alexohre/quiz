class AddQueuedForRecordingToQuizzes < ActiveRecord::Migration[7.1]
  def change
    add_column :quizzes, :queued_for_recording, :boolean
  end
end
