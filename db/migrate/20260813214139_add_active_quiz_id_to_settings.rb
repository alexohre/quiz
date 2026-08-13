class AddActiveQuizIdToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :active_quiz_id, :integer
  end
end
