class Order < ApplicationRecord
  belongs_to :user
  has_many :line_items
  has_many :payments, dependent: :destroy
  has_one :shipping_address, class_name: "Address", dependent: :destroy

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

  def unavailable_line_items
    line_items.includes(:product).select do |line_item|
      line_item.quantity > line_item.product.stock
    end
  end

  def stock_available?
    line_items.exists? && unavailable_line_items.empty?
  end

  def wait_for_payment!
    reserve_stock_and_transition!(:waiting_payment)
  end

  def complete!
    reserve_stock_and_transition!(:paid)
  end

  def cancel!
    transaction do
      lock!
      if stock_reserved_at.present?
        items = line_items.to_a
        Product.where(id: items.map(&:product_id).uniq).order(:id).lock.index_by(&:id).tap do |products|
          items.each do |item|
            product = products.fetch(item.product_id)
            product.update!(stock: product.stock + item.quantity)
          end
        end
        update!(stock_reserved_at: nil)
      end
      cancelled!
    end
  end

  private

  def reserve_stock_and_transition!(new_status)
    transaction do
      lock!

      if stock_reserved_at.nil?
        items = line_items.includes(:product).to_a
        raise ActiveRecord::RecordInvalid, self if items.empty?

        products = Product.where(id: items.map(&:product_id).uniq).order(:id).lock.index_by(&:id)
        unavailable = items.select { |item| item.quantity > products.fetch(item.product_id).stock }

        if unavailable.any?
          unavailable.each do |item|
            errors.add(:base, "Estoque insuficiente para #{products.fetch(item.product_id).name}")
          end
          raise ActiveRecord::RecordInvalid, self
        end

        items.each do |item|
          product = products.fetch(item.product_id)
          product.update!(stock: product.stock - item.quantity)
        end
        update!(stock_reserved_at: Time.current)
      end

      update!(status: new_status)
      capture_shipping_address! if new_status == :paid
      user.orders.find_or_create_by!(status: :cart)
    end
  end

  def capture_shipping_address!
    return if shipping_address.present?

    source_address = user.address
    unless source_address
      errors.add(:base, "Endereço de entrega não cadastrado")
      raise ActiveRecord::RecordInvalid, self
    end

    create_shipping_address!(source_address.attributes.slice(*Address::LOCATION_ATTRIBUTES))
  end
end
