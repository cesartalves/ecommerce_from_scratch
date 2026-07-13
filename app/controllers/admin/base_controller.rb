class Admin::BaseController < ApplicationController
  layout "admin"

  before_action :require_admin!

  def require_admin!
    redirect_to admin_login_path, alert: "Acesso restrito a administradores." unless current_user&.admin?
  end
end
