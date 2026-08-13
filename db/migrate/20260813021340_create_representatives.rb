class CreateRepresentatives < ActiveRecord::Migration[7.1]
  def change
    create_table :representatives do |t|
      t.string :name
      t.string :role
      t.string :phone
      t.references :church, null: false, foreign_key: true

      t.timestamps
    end
  end
end
