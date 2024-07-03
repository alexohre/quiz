class AddQuestionNumberToQuizzes < ActiveRecord::Migration[7.1]
  def change
    add_column :quizzes, :question_number, :integer
    add_index :quizzes, :question_number
  end
end
