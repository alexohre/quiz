class QuizController < ApplicationController

  def index 
    @stages = Stage.all.order(id: :asc)
    @active_stage = @stages.find_by(active: true)
    @quizzes = @active_stage.present? ? @active_stage.quizzes.order(question_number: :asc) : []
    
    ActionCable.server.broadcast('quiz_channel', { html: render_to_string(partial: 'wait') })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'wait') })
  end

  def show
    @quiz = Quiz.find(params[:id])
    @quiz.update(answered: true)
    
    # Check if auto-start is enabled
    settings = Setting.last
    Rails.logger.info "Auto-start check: settings=#{settings.inspect}"
    
    if settings&.auto_start && settings&.timer && settings.timer > 0
      Rails.logger.info "Auto-starting timer with duration: #{settings.timer}"
      # Add small delay to ensure page is fully loaded before starting timer
      Thread.new do
        sleep(0.5) # 500ms delay
        ActionCable.server.broadcast "timer_channel", { action: "start_timer", duration: settings.timer }
      end
    else
      Rails.logger.info "Auto-start conditions not met: auto_start=#{settings&.auto_start}, timer=#{settings&.timer}"
    end
    
    # Broadcast quiz update
    ActionCable.server.broadcast('quiz_channel', { html: render_to_string(partial: 'quiz_broadcast', locals: { quiz: @quiz }) })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'quiz_broadcast_timer', locals: { quiz: @quiz }) })
  end
end