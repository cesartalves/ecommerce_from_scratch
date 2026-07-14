class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.includes(:payments, user: :address).where.not(status: :cart).order(created_at: :desc)
  end
end
