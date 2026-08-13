class Church < ApplicationRecord
  validates :name, presence: true
  has_many :representatives, dependent: :destroy
end
