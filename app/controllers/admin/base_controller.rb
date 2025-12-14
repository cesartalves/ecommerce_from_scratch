class Admin::BaseController < ApplicationController
  layout 'admin'

  before_action :authenticate_user!
  before_action :require_admin!

  def require_admin!
    redirect_to admin_login_path, alert: "Not authorized" unless current_user&.admin?
  end
end