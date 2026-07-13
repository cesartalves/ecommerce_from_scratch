class Admin::OrdersController < Admin::BaseController
  def index
    @orders = Order.includes(:user, :payments).where.not(status: :cart).order(created_at: :desc)
  end
end
