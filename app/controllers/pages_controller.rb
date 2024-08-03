class PagesController < ApplicationController
  def home
  end

  def quiz
  end

  def scoreboard
  end

  def quizmaster
  end

  def judges
  end

  def timer
    
  end

  def reset
    @quizzes = Quiz.all
    if @quizzes.present?
      @quizzes.update_all(answered: false)
      redirect_to root_path, notice: "Quizzes reset successfully!"
    end
  end
end
