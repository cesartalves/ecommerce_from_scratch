class OrdersController < ApplicationController
  def index

  end

  def add
    product = Product.find(params[:product_id])

    order = current_user.orders.find_or_create_by(status: "cart")

    line_item = order.line_items.find_or_initialize_by(product: product)
    line_item.quantity ||= 0
    line_item.quantity += 1
    line_item.save!

    order.recalculate!

    redirect_to products_path, notice: "Produto adicionado ao carrinho"
  end
end
