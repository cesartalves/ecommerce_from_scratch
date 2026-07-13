class Admin::DashboardController < Admin::BaseController
  def index
    @paid_orders_count = Order.paid.count
    @waiting_orders_count = Order.waiting_payment.count
    @products_count = Product.count
    @revenue = Order.paid.sum(:total)
    @recent_orders = Order.includes(:user).where.not(status: :cart).order(created_at: :desc).limit(5)
  end
end
