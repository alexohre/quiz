class Stage < ApplicationRecord
  validates :name, presence: true

  has_many :quizzes

  def self.create_stages(number_of_stages)
    transaction do
      number_of_stages.times do |i|
        create!(
          name: "Stage #{i + 1}",
          active: i == 0 # set the first stage as active
        )
      end
    end
  end

  def self.active_stage
    find_by(active: true)
  end
end
