class QuizController < ApplicationController

  def index 
    @quizzes = Quiz.all.order(question_number: :asc)
  end

  def show
    @quiz = Quiz.find(params[:id])
    @quiz.update(answered: true)
  end
end