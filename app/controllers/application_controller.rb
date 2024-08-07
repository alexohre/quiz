class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :render_404

   private

  def render_404
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end
