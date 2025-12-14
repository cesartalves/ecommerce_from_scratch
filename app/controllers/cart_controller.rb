class CartController < ApplicationController
  def index
    @order = current_user.orders.find_or_create_by(status: "cart")
  end
end
