class PagesController < ApplicationController
  before_action :authenticate_quizmaster, only: [:quizmaster]
  before_action :authenticate_judges, only: [:judges]
  before_action :authenticate_timer, only: [:timer]
  before_action :authenticate_scoreboard, only: [:scoreboard]
  before_action :authenticate_recorder, only: [:recorder, :update_score, :skip_question, :finish_question, :reset_scores]
  
  def home
  end

  def recorder
    @stages = Stage.order(id: :asc)
    @churches = Church.includes(:scores, :representatives).order(:name)
    @setting = Setting.last || Setting.new
    @points_per_question = @setting.points_per_question || 10
    
    # Load all queued quizzes for recorder
    @queued_quizzes = Quiz.where(queued_for_recording: true).order(:id)
    
    if params[:quiz_id].present?
      @active_quiz = @queued_quizzes.find_by(id: params[:quiz_id]) || @queued_quizzes.first
    else
      @active_quiz = @queued_quizzes.first
    end

    @current_stage = params[:stage_id].present? ? Stage.find_by(id: params[:stage_id]) : (@active_quiz&.stage || @stages.find_by(active: true) || @stages.first)

    @current_round = params[:round_number].present? ? params[:round_number].to_i : 1
    max_rec_round = Score.where(stage: @current_stage).maximum(:round_number) || 1
    @max_round_count = [max_rec_round, 5, @current_round].max
  end

  def update_score
    church_id = params[:church_id]
    stage_id = params[:stage_id]
    round_number = params[:round_number].present? ? params[:round_number].to_i : 1
    points = params[:points].to_i
    bonus_points = params[:bonus_points].to_i
    quiz_id = params[:quiz_id]

    score = Score.find_or_initialize_by(church_id: church_id, stage_id: stage_id, round_number: round_number)
    score.points = [points, 0].max
    score.bonus_points = [bonus_points, 0].max

    if score.save
      # Dequeue recorded question once score is saved
      if quiz_id.present?
        Quiz.find_by(id: quiz_id)&.update(queued_for_recording: false)
      else
        Quiz.where(queued_for_recording: true, stage_id: stage_id).first&.update(queued_for_recording: false)
      end

      # Broadcast live score update
      ActionCable.server.broadcast("quiz_channel", {
        type: "score_update",
        church_id: score.church_id,
        church_name: score.church.name,
        stage_id: score.stage_id,
        stage_name: score.stage.name,
        round_number: score.round_number,
        points: score.points,
        bonus_points: score.bonus_points,
        round_total: score.total_stage_points,
        stage_total: score.church.score_for_stage(score.stage),
        grand_total: score.church.total_score,
        updated_by: current_user&.email || "Recorder"
      })

      # Auto advance to next question in queue
      next_queued = Quiz.where(queued_for_recording: true).first

      ActionCable.server.broadcast("quiz_channel", {
        type: "queue_updated",
        remaining_count: Quiz.where(queued_for_recording: true).count
      })

      if next_queued.present?
        redirect_to recorder_path(stage_id: next_queued.stage_id, quiz_id: next_queued.id), notice: "Score saved for #{score.church.name}! Advanced to next question in queue."
      else
        redirect_to recorder_path(stage_id: stage_id, round_number: round_number), notice: "Score saved for #{score.church.name}! Queue cleared."
      end
    else
      redirect_to recorder_path(stage_id: stage_id, round_number: round_number, quiz_id: quiz_id), alert: "Could not update score."
    end
  end

  def finish_question
    quiz_id = params[:quiz_id]
    stage_id = params[:stage_id]
    round_number = params[:round_number].to_i

    if quiz_id.present?
      Quiz.find_by(id: quiz_id)&.update(queued_for_recording: false)
    else
      Quiz.where(queued_for_recording: true, stage_id: stage_id).first&.update(queued_for_recording: false)
    end

    next_queued = Quiz.where(queued_for_recording: true).first

    ActionCable.server.broadcast("quiz_channel", {
      type: "queue_updated",
      remaining_count: Quiz.where(queued_for_recording: true).count,
      message: "Question completed in recorder queue."
    })

    if next_queued.present?
      redirect_to recorder_path(stage_id: next_queued.stage_id, quiz_id: next_queued.id), notice: "Advanced to next question in queue."
    else
      redirect_to recorder_path(stage_id: stage_id, round_number: round_number), notice: "Queue cleared! Waiting for Quiz Master to load new questions."
    end
  end

  def skip_question
    stage_id = params[:stage_id]
    round_number = params[:round_number].to_i
    church_id = params[:church_id]
    quiz_id = params[:quiz_id]

    if church_id.present? && stage_id.present?
      score = Score.find_by(church_id: church_id, stage_id: stage_id, round_number: round_number)
      score&.destroy
    end

    # Dequeue skipped question
    if quiz_id.present?
      Quiz.find_by(id: quiz_id)&.update(queued_for_recording: false)
    else
      Quiz.where(queued_for_recording: true, stage_id: stage_id).first&.update(queued_for_recording: false)
    end

    next_queued = Quiz.where(queued_for_recording: true).first

    ActionCable.server.broadcast("quiz_channel", {
      type: "queue_updated",
      remaining_count: Quiz.where(queued_for_recording: true).count,
      message: "Question skipped/disqualified."
    })

    if next_queued.present?
      redirect_to recorder_path(stage_id: next_queued.stage_id, quiz_id: next_queued.id), notice: "Question skipped. Advanced to next question in queue."
    else
      redirect_to recorder_path(stage_id: stage_id, round_number: round_number), notice: "Question skipped. Queue cleared."
    end
  end

  def reset_scores
    Score.destroy_all
    Quiz.update_all(queued_for_recording: false)
    Setting.last&.update(active_quiz_id: nil)
    ActionCable.server.broadcast("quiz_channel", { type: "scores_reset" })
    redirect_to recorder_path, notice: "All recorded scores and queue have been reset."
  end

  def scoreboard
    @stages = Stage.order(id: :asc)
    @current_stage = params[:stage_id].present? ? Stage.find_by(id: params[:stage_id]) : (@stages.find_by(active: true) || @stages.first)
    @churches = Church.includes(:scores, :representatives).all.sort_by { |c| -c.total_score }
    @show_overall = params[:show_overall] == "1"
  end

  def quizmaster
  end

  def judges
  end

  def timer
  end

  private

  def authenticate_quizmaster
    unless current_user&.admin? || current_user&.quiz_master?
      redirect_to "/404"
    end
  end

  def authenticate_judges
    unless current_user&.admin? || current_user&.judges?
      redirect_to "/404"
    end
  end

  def authenticate_timer
    unless current_user&.admin? || current_user&.time_keeper?
      redirect_to "/404"
    end
  end

  def authenticate_scoreboard
    unless current_user&.admin? || current_user&.presenter? || current_user&.recorder?
      redirect_to "/404"
    end
  end

  def authenticate_recorder
    unless current_user&.admin? || current_user&.recorder?
      redirect_to "/404"
    end
  end
end
