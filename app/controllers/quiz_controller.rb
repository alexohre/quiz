class QuizController < ApplicationController

  def index 
    @stages = Stage.all.order(id: :asc)
    @active_stage = @stages.find_by(active: true) || @stages.first
    @quizzes = @active_stage.present? ? @active_stage.quizzes.order(question_number: :asc) : []
    @churches = Church.includes(:scores, :representatives).all.sort_by { |c| -c.total_score }
    
    settings = Setting.last
    ActionCable.server.broadcast("timer_channel", { action: "reset_timer", duration: settings&.timer || 30 })

    ActionCable.server.broadcast('quiz_channel', { 
      type: 'presenter_wait',
      html: render_to_string(partial: 'wait') 
    })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'wait') })
  end

  def show
    @quiz = Quiz.find(params[:id])
    was_already_answered = @quiz.answered?
    # Only queue fresh unopened questions for recording. Re-opened questions do NOT queue.
    @quiz.update(answered: true, queued_for_recording: !was_already_answered)
    
    @stages = Stage.all.order(id: :asc)
    @active_stage = @quiz.stage || @stages.find_by(active: true) || @stages.first
    @churches = Church.includes(:scores, :representatives).all.sort_by { |c| -c.total_score }
    
    # Store active quiz ID in settings
    settings = Setting.last || Setting.create!
    settings.update(active_quiz_id: @quiz.id)
    
    if was_already_answered
      # Question was previously opened/answered: Stop timer & set duration to 0 so it does not count down
      ActionCable.server.broadcast("timer_channel", { action: "reset_timer", duration: 0 })
    else
      # Fresh unopened question: Reset timer to full configured duration
      ActionCable.server.broadcast("timer_channel", { action: "reset_timer", duration: settings.timer || 30 })

      # Auto-start timer ONLY for fresh unopened questions
      if settings&.auto_start && settings&.timer && settings.timer > 0
        Rails.logger.info "Auto-starting timer with duration: #{settings.timer} for fresh question ##{@quiz.question_number}"
        Thread.new do
          sleep(0.5) # 500ms delay
          ActionCable.server.broadcast "timer_channel", { action: "start_timer", duration: settings.timer }
        end
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
      already_answered: was_already_answered,
      html: render_to_string(partial: 'quiz_broadcast', locals: { quiz: @quiz }) 
    })
    ActionCable.server.broadcast('quiz_timer_channel', { html: render_to_string(partial: 'quiz_broadcast_timer', locals: { quiz: @quiz }) })
  end
end