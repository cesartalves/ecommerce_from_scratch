class Admin::CustomersController < Admin::BaseController
  def show
    @customer = User.includes(:address).find(params[:id])
    @orders = @customer.orders.where.not(status: :cart).order(created_at: :desc)
  end
end
