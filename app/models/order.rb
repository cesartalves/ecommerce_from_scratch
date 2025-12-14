class Order < ApplicationRecord
  belongs_to :user

  enum status: {
    pending: 0,
    paid: 1,
    cancelled: 2
  }

  validates :total, numericality: { greater_than_or_equal_to: 0 }
end
