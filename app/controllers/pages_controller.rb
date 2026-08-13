class PagesController < ApplicationController
  before_action :authenticate_quizmaster, only: [:quizmaster]
  before_action :authenticate_judges, only: [:judges]
  before_action :authenticate_timer, only: [:timer]
  before_action :authenticate_scoreboard, only: [:scoreboard]
  before_action :authenticate_recorder, only: [:recorder, :update_score, :reset_scores]
  
  def home
  end

  def recorder
    @stages = Stage.order(id: :asc)
    @current_stage = params[:stage_id].present? ? Stage.find_by(id: params[:stage_id]) : (@stages.find_by(active: true) || @stages.first)
    @churches = Church.includes(:scores, :representatives).order(:name)
    @setting = Setting.last || Setting.new
    @points_per_question = @setting.points_per_question || 10
    
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

    score = Score.find_or_initialize_by(church_id: church_id, stage_id: stage_id, round_number: round_number)
    score.points = [points, 0].max
    score.bonus_points = [bonus_points, 0].max

    if score.save
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

      redirect_to recorder_path(stage_id: stage_id, round_number: round_number), notice: "Score for #{score.church.name} (Round #{round_number}) updated: #{score.points} pts (+#{score.bonus_points} bonus)!"
    else
      redirect_to recorder_path(stage_id: stage_id, round_number: round_number), alert: "Could not update score."
    end
  end

  def reset_scores
    Score.destroy_all
    ActionCable.server.broadcast("quiz_channel", { type: "scores_reset" })
    redirect_to recorder_path, notice: "All recorded scores have been reset."
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
