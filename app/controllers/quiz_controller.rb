class QuizController < ApplicationController

  def index 
    @stages = Stage.all.order(id: :asc)
    @active_stage = @stages.find_by(active: true)
    @quizzes = @active_stage.present? ? @active_stage.quizzes.order(question_number: :asc) : []
    
    ActionCable.server.broadcast('quiz_channel', { 
      type: 'presenter_wait',
      html: render_to_string(partial: 'wait') 
    })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'wait') })
  end

  def show
    @quiz = Quiz.find(params[:id])
    @quiz.update(answered: true, queued_for_recording: true)
    
    # Store active quiz ID in settings
    settings = Setting.last || Setting.create!
    settings.update(active_quiz_id: @quiz.id)
    
    # Check if auto-start is enabled
    if settings&.auto_start && settings&.timer && settings.timer > 0
      Rails.logger.info "Auto-starting timer with duration: #{settings.timer}"
      Thread.new do
        sleep(0.5) # 500ms delay
        ActionCable.server.broadcast "timer_channel", { action: "start_timer", duration: settings.timer }
      end
    end
    
    # Broadcast quiz update with question metadata
    ActionCable.server.broadcast('quiz_channel', { 
      type: 'question_queued',
      question_id: @quiz.id,
      question_number: @quiz.question_number,
      stage_id: @quiz.stage_id,
      stage_name: @quiz.stage&.name || "Stage",
      question_text: @quiz.question,
      html: render_to_string(partial: 'quiz_broadcast', locals: { quiz: @quiz }) 
    })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'quiz_broadcast_timer', locals: { quiz: @quiz }) })
  end
end