class Representative < ApplicationRecord
  belongs_to :church
  validates :name, presence: true
end
