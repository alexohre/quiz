class QuizController < ApplicationController

  def index 
    @stages = Stage.all.order(id: :asc)
    @active_stage = @stages.find_by(active: true)
    @quizzes = @active_stage ? @active_stage.quizzes.order(question_number: :asc) : ["No question here!"]
    # @quizzes = Quiz.all.order(question_number: :asc)
    ActionCable.server.broadcast('quiz_channel', { html: render_to_string(partial: 'wait') })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'wait') })
  end

  def show
    @quiz = Quiz.find(params[:id])
    @quiz.update(answered: true)
    # Broadcast quiz update
    ActionCable.server.broadcast('quiz_channel', { html: render_to_string(partial: 'quiz_broadcast', locals: { quiz: @quiz }) })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'quiz_broadcast_timer', locals: { quiz: @quiz }) })
  end
end