class PagesController < ApplicationController
  # before_action :authenticate_user!
  layout "auth", only: [:login]
  def home
  end

  def login
  end

  def scoreboard
  end

  def quizmaster
  end

  def judges
  end

  def timer
    
  end
end
