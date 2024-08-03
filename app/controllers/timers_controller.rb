class TimersController < ApplicationController
  def start
    duration = params[:duration].to_i
    ActionCable.server.broadcast "timer_channel", { action: "start_timer", duration: duration }
    head :ok
  end
end