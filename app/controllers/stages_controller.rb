class StagesController < ApplicationController

  def activate
    @stage = Stage.find(params[:id])
    Stage.transaction do
      Stage.update_all(active: false)
      @stage.update!(active: true)
    end
    redirect_to quiz_index_path
  end
end