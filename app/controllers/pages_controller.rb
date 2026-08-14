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
      @active_quiz = @queued_quizzes.find_by(id: params[:quiz_id])
    else
      @active_quiz = @queued_quizzes.first
    end

    @current_stage = params[:stage_id].present? ? Stage.find_by(id: params[:stage_id]) : (@active_quiz&.stage || @stages.find_by(active: true) || @stages.first)

    # Filter churches active for current stage
    @churches = Church.includes(:scores, :representatives, :stage_eliminations).active_in_stage(@current_stage).order(:name)

    if params[:round_number].present?
      @current_round = params[:round_number].to_i
    else
      # Auto land on first incomplete round for active congregations in current stage
      active_church_ids = @churches.map(&:id)
      churches_count = active_church_ids.size
      active_round = 1
      if churches_count > 0 && @current_stage.present?
        (1..10).each do |r_num|
          recorded_count = Score.where(stage_id: @current_stage.id, round_number: r_num, church_id: active_church_ids).count
          if recorded_count >= churches_count
            active_round = r_num + 1
          else
            active_round = r_num
            break
          end
        end
      end
      @current_round = active_round
    end

    max_rec_round = Score.where(stage: @current_stage).maximum(:round_number) || 1
    @max_round_count = [max_rec_round, 5, @current_round].max

    # Flag if the active question/round was previously answered or recorded
    @is_already_recorded = @active_quiz.present? && (@active_quiz.answered? || Score.exists?(stage_id: @current_stage&.id, round_number: @current_round))
  end

  def update_score
    church_id = params[:church_id]
    stage_id = params[:stage_id]
    round_number = params[:round_number].present? ? params[:round_number].to_i : 1
    points = [params[:points].to_i, 0].max
    bonus_points = [params[:bonus_points].to_i, 0].max
    quiz_id = params[:quiz_id]

    # Check if score already existed before save to detect modifications/rollbacks
    existing_score = Score.find_by(church_id: church_id, stage_id: stage_id, round_number: round_number)
    is_modification = existing_score.present?

    # Prevent double recording identical score values
    if existing_score && existing_score.points == points && existing_score.bonus_points == bonus_points
      # Dequeue recorded question if still queued
      Quiz.find_by(id: quiz_id)&.update(queued_for_recording: false) if quiz_id.present?
      
      redirect_to recorder_path(stage_id: stage_id, round_number: round_number), notice: "Score for #{existing_score.church.name} is already recorded (#{existing_score.total_stage_points} pts)."
      return
    end

    score = Score.find_or_initialize_by(church_id: church_id, stage_id: stage_id, round_number: round_number)
    score.points = points
    score.bonus_points = bonus_points

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

      # Broadcast live ticker news feed
      quiz_obj = quiz_id.present? ? Quiz.find_by(id: quiz_id) : nil
      q_num = quiz_obj ? quiz_obj.formatted_question_number : (quiz_id.present? ? quiz_id : "1")
      total_pts = score.points + score.bonus_points

      ticker_msg = if is_modification
        "record modified to #{total_pts} pts for #{score.church.name}, question ##{q_num}"
      elsif points == 0 && bonus_points == 0
        "0 pts (failed) recorded for #{score.church.name}, question ##{q_num}"
      elsif bonus_points > 0 && points == 0
        "#{bonus_points} pts manually recorded for #{score.church.name}, question ##{q_num}"
      elsif bonus_points > 0 && points > 0
        "#{points} pts & #{bonus_points} pts manual bonus recorded for #{score.church.name}, question ##{q_num}"
      else
        "#{points} pts recorded for #{score.church.name}, question ##{q_num}"
      end

      ActionCable.server.broadcast("quiz_channel", {
        type: "ticker_feed",
        message: ticker_msg
      })

      # Auto advance to next question in queue
      next_queued = Quiz.where(queued_for_recording: true).first

      ActionCable.server.broadcast("quiz_channel", {
        type: "queue_updated",
        remaining_count: Quiz.where(queued_for_recording: true).count
      })

      # Auto advance to next round tab if current round is complete for active congregations in this stage
      active_churches_in_stage = Church.active_in_stage(stage_id)
      churches_count = active_churches_in_stage.count
      recorded_in_round = Score.where(stage_id: stage_id, round_number: round_number, church_id: active_churches_in_stage.select(:id)).count
      round_is_complete = churches_count > 0 && recorded_in_round >= churches_count
      target_round = round_is_complete ? round_number + 1 : round_number

      if next_queued.present?
        redirect_to recorder_path(stage_id: next_queued.stage_id, quiz_id: next_queued.id, round_number: target_round), notice: "Score saved for #{score.church.name}! Advanced to next question."
      else
        msg = round_is_complete ? "Round #{round_number} complete! Auto-advanced to Round #{target_round}." : "Score saved for #{score.church.name}!"
        redirect_to recorder_path(stage_id: stage_id, round_number: target_round), notice: msg
      end
    else
      redirect_to recorder_path(stage_id: stage_id, round_number: round_number, quiz_id: quiz_id), alert: "Could not update score."
    end
  end

  def rollback_question
    last_quiz = Quiz.where(queued_for_recording: true).or(Quiz.where(answered: true)).order(updated_at: :desc).first

    if last_quiz
      last_quiz.update(queued_for_recording: true)
      
      settings = Setting.last || Setting.create!
      settings.update(active_quiz_id: last_quiz.id)

      ActionCable.server.broadcast("quiz_channel", {
        type: "queue_updated",
        question_id: last_quiz.id,
        question_number: last_quiz.question_number,
        question_text: last_quiz.question,
        remaining_count: Quiz.where(queued_for_recording: true).count
      })

      ActionCable.server.broadcast("quiz_channel", {
        type: "ticker_feed",
        message: "rolled back to question ##{last_quiz.formatted_question_number} for score modification"
      })

      redirect_to recorder_path(stage_id: last_quiz.stage_id, quiz_id: last_quiz.id), notice: "Rolled back to Question ##{last_quiz.formatted_question_number}. You can now modify and re-save scores."
    else
      redirect_to recorder_path(stage_id: params[:stage_id], round_number: params[:round_number]), alert: "No previous question found to rollback."
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

    quiz_obj = quiz_id.present? ? Quiz.find_by(id: quiz_id) : nil
    q_label = quiz_obj ? "question ##{quiz_obj.formatted_question_number}" : (quiz_id.present? ? "question ##{quiz_id}" : "question")
    ticker_msg = "#{q_label} record skipped"

    ActionCable.server.broadcast("quiz_channel", {
      type: "ticker_feed",
      message: ticker_msg
    })

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
    unless current_user&.admin?
      redirect_to recorder_path, alert: "Access Denied: Only administrators can reset all scores."
      return
    end

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
