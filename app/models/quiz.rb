class Quiz < ApplicationRecord
  belongs_to :stage

  def formatted_question_number
    question_number.to_s.rjust(2, '0')
  end
end
