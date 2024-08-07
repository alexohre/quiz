class PagesController < ApplicationController
  before_action :authenticate_quizmaster, only: [:quizmaster]
  before_action :authenticate_judges, only: [:judges]
  before_action :authenticate_timer, only: [:timer]
  before_action :authenticate_scoreboard, only: [:scoreboard]
  before_action :authenticate_recorder, only: [:recorder]
  
  def home
  end

  def recorder
  end

  def scoreboard
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
