class SettingsController < ApplicationController
  require 'csv'
  
  def settings
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


  private

  def quiz_params
    params.require(:quiz).permit(:stage_id, :question_number, :question, :answer)
  end

end
