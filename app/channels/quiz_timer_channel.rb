class QuizTimerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "quiz_timer_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
