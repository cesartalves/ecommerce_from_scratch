class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items

  enum status: {
    pending: 0,
    paid: 1,
    cancelled: 2,
    cart: 3
  }

  validates :total, numericality: { greater_than_or_equal_to: 0 }

  def recalculate!
    total = line_items.map { |li| li.quantity * li.product.price }.sum
    update!(total: total)
  end
end
