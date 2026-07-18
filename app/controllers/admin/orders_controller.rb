class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.includes(:payments, user: :address).where.not(status: :cart).order(created_at: :desc)
  end

  def show
    @order = Order.includes(:payments, :shipping_address, line_items: :product).find(params[:id])
  end
end
