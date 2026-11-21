class Transaction < ApplicationRecord
  belongs_to :account

  validates :external_id, presence: true
end
