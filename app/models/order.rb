class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items
  has_many :payments, dependent: :destroy

  enum :status, {
    pending: "pending",
    waiting_payment: "waiting_payment",
    paid: "paid",
    cancelled: "cancelled",
    cart: "cart"
  }

  validates :total, numericality: { greater_than_or_equal_to: 0 }

  def recalculate!
    total = line_items.map { |li| li.quantity * li.product.price }.sum
    update!(total: total)
  end

  def latest_pix_payment
    payments.select(&:pix?).max_by(&:created_at)
  end

  def complete!
    transaction do
      paid!
      user.orders.find_or_create_by!(status: :cart)
    end
  end
end
