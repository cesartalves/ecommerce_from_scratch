class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index

  end

  private

  

  def require_admin
    redirect_to admin_login_path, alert: "Not authorized" unless current_user&.admin?
  end
end
