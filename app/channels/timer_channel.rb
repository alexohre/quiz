class TimerChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "timer_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def start_timer(data)
    ActionCable.server.broadcast "timer_channel", { action: "start_timer", duration: data["duration"] }
  end
end
