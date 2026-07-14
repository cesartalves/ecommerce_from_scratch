class CartController < ApplicationController
  def index
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "Faça login para acessar seu carrinho."
      return
    end

    @order = current_user.cart_order
    @unavailable_line_items = @order.unavailable_line_items
  end
end
