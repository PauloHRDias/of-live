class Consent < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true
end
