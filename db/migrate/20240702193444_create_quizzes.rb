class CreateQuizzes < ActiveRecord::Migration[7.1]
  def change
    create_table :quizzes do |t|
      t.text :question
      t.string :answer
      t.boolean :answered, default: false
      t.belongs_to :stages, null: false, foreign_key: true

      t.timestamps
    end
    add_index :quizzes, :question
    add_index :quizzes, :answer
  end
end
