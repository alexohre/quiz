class SettingsController < ApplicationController
  before_action :check_admin_user
  require 'csv'
  
  def settings
    @stages = Stage.includes(:quizzes).order(id: :asc)
    @timers = Setting.last
    @timer = @timers.present? ? @timers.timer : 0
  end

  def stage 
    @stage = Stage.count
    if params[:number_of_stages].present?
      number_of_stages = params[:number_of_stages].to_i
      if number_of_stages > 0
        Stage.create_stages(number_of_stages)
        redirect_to settings_settings_path, notice: "#{number_of_stages} stages created successfully."
      else
        redirect_to settings_settings_path, alert: "Please enter a valid number of stages."
      end
    end
  end

  def drop_db
    @quizzes = Quiz.all
    if @quizzes.present?
      @quizzes.destroy_all
    end
    @stages = Stage.all 
    if @stages.present?
      @stages.destroy_all
    end
    redirect_to settings_settings_path, notice: "Data successfully deleted!"
  end

  def upload
  end

  def uploader
    csv_file = params[:file]
    stage_id = params[:stage_id].to_i
    number_start = params[:number_start].to_i

    if csv_file.present? && csv_file.content_type == 'text/csv'
      errors = []
      current_max_number = Quiz.maximum(:question_number) || 0
      next_question_number = number_start > 0 ? number_start : current_max_number + 1

      CSV.foreach(csv_file.path, headers: true).with_index(next_question_number) do |row, index|
        quiz_params = {
          question: row['Question'],
          answer: row['Answer'],
          answered: row['answered'].present? && row['answered'].strip.downcase == 'true',
          stage_id: stage_id,
          question_number: index
        }

        quiz = Quiz.new(quiz_params)
        unless quiz.save
          errors << "Row #{index - next_question_number + 1}: #{quiz.errors.full_messages.join(", ")}"
        end
      end

      if errors.empty?
        redirect_to settings_upload_path, notice: 'Questions were successfully imported from CSV.'
      else
        redirect_to settings_upload_path, alert: "There were errors with some records: #{errors.join("; ")}"
      end
    else
      redirect_to settings_upload_path, alert: 'Invalid file format. Please upload a CSV file.'
    end
  rescue => e
    redirect_to settings_upload_path, alert: "There was an error processing the file: #{e.message}"
  end

  def timer
    @timers = Setting.last || Setting.new(timer: 60, auto_start: false, points_per_question: 10)
    @timer = @timers.timer || 60
    @auto_start = @timers.auto_start || false
    @points_per_question = @timers.points_per_question || 10

    if params[:setting].present? || params[:timer].present? || params[:auto_start].present? || params[:points_per_question].present?
      if params[:setting].present?
        timer_value = params[:setting][:timer].to_i
        auto_start_value = params[:setting][:auto_start] == '1'
        points_per_q = params[:setting][:points_per_question].to_i
      else
        timer_value = params[:timer].present? ? params[:timer].to_i : (@timers.timer || 60)
        auto_start_value = params[:auto_start] == '1'
        points_per_q = params[:points_per_question].present? ? params[:points_per_question].to_i : (@timers.points_per_question || 10)
      end
      
      points_per_q = 10 if points_per_q <= 0
      
      if timer_value <= 0
        redirect_to settings_timer_path, alert: "Please enter a valid number of seconds."
        return
      end
      
      if @timers.persisted?
        @timers.update!(timer: timer_value, auto_start: auto_start_value, points_per_question: points_per_q)
      else
        Setting.create!(timer: timer_value, auto_start: auto_start_value, points_per_question: points_per_q)
      end
      
      redirect_to settings_timer_path, notice: "Quiz settings updated: #{timer_value}s timer, #{points_per_q} pts/question."
    end
  end

  def users 
    @users = User.all
  end

  def create_user
    email = params[:email]
    password = params[:password]
    visible_password = params[:password]
    role = params[:role]

    user = User.create!(email: email, password: password, role: role, visible_password: visible_password)

    if user.present?
      redirect_to settings_users_path, notice: "User with #{user.email} was successfully created."
    else
      redirect_to settings_users_path, alert: 'Oops, something went wrong please try again!'
    end
  end

  def update_user_password
    id = params[:user_id]
    password = params[:password]

    @user = User.find_by(id: id)

    if @user.nil?
      redirect_to settings_users_path, alert: 'User not found.'
      return
    end

    if @user.update(password: password, visible_password: password)
      if @user == current_user
        sign_out(@user)
        redirect_to new_user_session_path, notice: 'Password was successfully updated. Please sign in again with your new password.'
      else
        redirect_to settings_users_path, notice: 'Password was successfully updated.'
      end
    else
      redirect_to settings_users_path, alert: 'Oops, Something went Wrong!'
    end
  end

  def delete_user
    @user = User.find(params[:id])
    if @user.destroy
      redirect_to settings_users_path, notice: 'User was successfully deleted.'
    else
      redirect_to settings_users_path, alert: 'Oops, something went wrong, please try again!'
    end
  end

  def reset
    @quizzes = Quiz.all
    if @quizzes.present?
      @quizzes.update_all(answered: false)
      redirect_to settings_settings_path, notice: "Quizzes reset successfully!"
    else
      redirect_to settings_settings_path, alert: "Oops, Something went wrong!"
    end
  end

  def churches
    @churches = Church.includes(:representatives).order(created_at: :desc)
  end

  def create_church
    name = params[:name]
    location = params[:location]

    if name.present?
      church = Church.create(name: name, location: location)
      if church.persisted?
        redirect_to settings_churches_path, notice: "Church/Congregation '#{church.name}' was successfully created."
      else
        redirect_to settings_churches_path, alert: "Failed to create church: #{church.errors.full_messages.join(', ')}"
      end
    else
      redirect_to settings_churches_path, alert: "Please provide a valid Church/Congregation name."
    end
  end

  def delete_church
    @church = Church.find_by(id: params[:id])
    if @church&.destroy
      redirect_to settings_churches_path, notice: "Church was successfully deleted."
    else
      redirect_to settings_churches_path, alert: "Could not delete church."
    end
  end

  def create_representative
    name = params[:name]
    role = params[:role]
    phone = params[:phone]
    church_id = params[:church_id]

    if name.present? && church_id.present?
      rep = Representative.create(name: name, role: role, phone: phone, church_id: church_id)
      if rep.persisted?
        redirect_to settings_churches_path, notice: "Representative '#{rep.name}' added successfully."
      else
        redirect_to settings_churches_path, alert: "Failed to add representative: #{rep.errors.full_messages.join(', ')}"
      end
    else
      redirect_to settings_churches_path, alert: "Please provide representative name and target church."
    end
  end

  def delete_representative
    @rep = Representative.find_by(id: params[:id])
    if @rep&.destroy
      redirect_to settings_churches_path, notice: "Representative was successfully deleted."
    else
      redirect_to settings_churches_path, alert: "Could not delete representative."
    end
  end

  def analysis
    @stages = Stage.includes(:quizzes).order(id: :asc)
    @churches = Church.includes(:scores, :representatives).all.sort_by { |c| -c.total_score }
    @all_quizzes = Quiz.all
    @total_quizzes_count = @all_quizzes.count
    @answered_quizzes_count = @all_quizzes.where(answered: true).count
    @remaining_quizzes_count = @total_quizzes_count - @answered_quizzes_count
    @progress_percentage = @total_quizzes_count > 0 ? ((@answered_quizzes_count.to_f / @total_quizzes_count) * 100).round(1) : 0

    # Overall points analytics
    @all_scores = Score.all
    @total_base_points = @all_scores.sum(:points)
    @total_bonus_points = @all_scores.sum(:bonus_points)
    @total_points_awarded = @total_base_points + @total_bonus_points

    # Success / Failure Rate
    @total_score_records = @all_scores.count
    @passed_records = @all_scores.where('points > 0 OR bonus_points > 0').count
    @failed_records = @all_scores.where(points: 0, bonus_points: 0).count
    @overall_pass_rate = @total_score_records > 0 ? ((@passed_records.to_f / @total_score_records) * 100).round(1) : 0

    # Congregation Reports Breakdown
    @congregation_reports = @churches.map do |church|
      c_scores = church.scores
      attempts = c_scores.count
      passed = c_scores.where('points > 0 OR bonus_points > 0').count
      failed = c_scores.where(points: 0, bonus_points: 0).count
      base_pts = c_scores.sum(:points)
      bonus_pts = c_scores.sum(:bonus_points)
      total_pts = base_pts + bonus_pts
      pass_rate = attempts > 0 ? ((passed.to_f / attempts) * 100).round(1) : 0

      stage_breakdown = @stages.map do |stg|
        stg_scores = c_scores.where(stage_id: stg.id)
        stg_attempts = stg_scores.count
        stg_base = stg_scores.sum(:points)
        stg_bonus = stg_scores.sum(:bonus_points)
        stg_total = stg_base + stg_bonus
        { stage: stg, attempts: stg_attempts, base: stg_base, bonus: stg_bonus, total: stg_total }
      end

      {
        church: church,
        grand_total: total_pts,
        base_points: base_pts,
        bonus_points: bonus_pts,
        attempts: attempts,
        passed: passed,
        failed: failed,
        pass_rate: pass_rate,
        stage_breakdown: stage_breakdown
      }
    end
  end

  def church_analysis
    @church = Church.includes(:scores, :representatives).find(params[:id])
    @stages = Stage.includes(:quizzes).order(id: :asc)
    @all_churches_sorted = Church.all.sort_by { |c| -c.total_score }
    @rank = (@all_churches_sorted.index(@church) || 0) + 1

    @scores = @church.scores.includes(:stage).order(stage_id: :asc, round_number: :asc)
    @total_attempts = @scores.count
    @passed_scores = @scores.where('points > 0 OR bonus_points > 0')
    @failed_scores = @scores.where(points: 0, bonus_points: 0)

    @passed_count = @passed_scores.count
    @failed_count = @failed_scores.count
    @total_base = @scores.sum(:points)
    @total_bonus = @scores.sum(:bonus_points)
    @grand_total = @total_base + @total_bonus
    @pass_rate = @total_attempts > 0 ? ((@passed_count.to_f / @total_attempts) * 100).round(1) : 0

    # Build question-by-question detailed breakdown list
    @question_breakdowns = @scores.map do |score|
      quiz = Quiz.where(stage_id: score.stage_id).order(:question_number).offset(score.round_number - 1).first
      q_number = quiz ? quiz.formatted_question_number : "#{score.round_number}"
      q_text = quiz ? quiz.question : "Question ##{score.round_number} for #{score.stage.name}"
      q_answer = quiz ? quiz.answer : nil
      is_passed = score.points > 0 || score.bonus_points > 0

      {
        score: score,
        quiz: quiz,
        question_number: q_number,
        question_text: q_text,
        question_answer: q_answer,
        stage_name: score.stage.name,
        round_number: score.round_number,
        points: score.points,
        bonus_points: score.bonus_points,
        total_pts: score.total_stage_points,
        is_passed: is_passed,
        updated_at: score.updated_at
      }
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :role, :visible_password)
  end

  def quiz_params
    params.require(:quiz).permit(:stage_id, :question_number, :question, :answer)
  end

  def check_admin_user
    unless current_user&.admin?
      redirect_to "/404"
    end
  end

end
