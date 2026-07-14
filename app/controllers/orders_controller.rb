class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders
                          .where(status: %i[paid waiting_payment])
                          .includes(:payments)
                          .order(created_at: :desc)
  end

  def add
    product = Product.find(params[:product_id])

    order = current_user.cart_order

    line_item = order.line_items.find_or_initialize_by(product: product)
    line_item.quantity ||= 0
    line_item.price ||= product.price
    if line_item.quantity >= product.stock
      return redirect_to cart_path, alert: "Não há mais unidades de #{product.name} em estoque."
    end
    line_item.quantity += 1
    line_item.save!

    order.recalculate!

    redirect_to cart_path
  end

  def remove
    item = current_user.cart_order.line_items.find_by(product_id: params[:product_id])
    return redirect_back(fallback_location: root_path) unless item

    item.quantity -= 1

    if item.quantity <= 0
      item.destroy
    else
      item.save!
    end

    current_user.cart_order.recalculate!

    redirect_back fallback_location: root_path
  end
end
