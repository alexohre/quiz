class Stage < ApplicationRecord
  validates :name, presence: true

  has_many :quizzes, dependent: :destroy
  has_many :scores, dependent: :destroy

  def self.create_stages(number_of_stages)
    transaction do
      existing_stages = order(:id).to_a
      
      if existing_stages.empty?
        number_of_stages.times do |i|
          create!(
            name: "Stage #{i + 1}",
            active: i == 0
          )
        end
      elsif existing_stages.length < number_of_stages
        existing_stages.each_with_index do |st, i|
          st.update!(name: "Stage #{i + 1}")
        end
        (existing_stages.length...number_of_stages).each do |i|
          create!(
            name: "Stage #{i + 1}",
            active: false
          )
        end
      else
        existing_stages.each_with_index do |st, i|
          st.update!(name: "Stage #{i + 1}")
        end
      end
    end
  end

  def self.active_stage
    find_by(active: true) || first
  end
end
