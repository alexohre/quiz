class AddActiveToStages < ActiveRecord::Migration[7.1]
  def change
    add_column :stages, :active, :boolean
  end
end
