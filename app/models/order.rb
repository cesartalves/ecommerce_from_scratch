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
  validates :shipping_cost, numericality: { greater_than_or_equal_to: 0 }

  def items_total
    line_items.sum { |line_item| line_item.quantity * line_item.product.price }
  end

  def recalculate!
    update!(
      total: items_total,
      shipping_cost: 0,
      shipping_service: nil,
      shipping_service_code: nil,
      shipping_days: nil
    )
  end

  def shipping_package
    Correios::Package.from_line_items(line_items.includes(:product))
  end

  def apply_shipping!(quote)
    update!(
      shipping_cost: quote.price,
      shipping_service: quote.service_name,
      shipping_service_code: quote.service_code,
      shipping_days: quote.delivery_days,
      total: items_total + quote.price
    )
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
