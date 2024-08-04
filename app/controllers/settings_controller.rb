class SettingsController < ApplicationController
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
    @timers = Setting.last
    @timer = @timers.present? ? @timers.timer : 0

    if params[:timer].present?
      timer_value = params[:timer].to_i
      if timer_value > 0
        # Update the existing setting or create a new one if it doesn't exist
        if @timers.present?
          @timers.update!(timer: timer_value)
        else
          Setting.create!(timer: timer_value)
        end
        redirect_to settings_timer_path, notice: "#{timer_value} seconds updated successfully."
      else
        redirect_to settings_timer_path, alert: "Please enter a valid number of seconds."
      end
    end
  end

  def users 
    
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

  private

  def quiz_params
    params.require(:quiz).permit(:stage_id, :question_number, :question, :answer)
  end

end
