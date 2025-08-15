class AddAutoStartToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :auto_start, :boolean, default: false
  end
end
