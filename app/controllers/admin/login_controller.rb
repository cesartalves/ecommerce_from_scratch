class Admin::LoginController < ApplicationController
  layout "admin"

  def login
    @user = User.new
  end

  def create
    # Find user by email
    @user = User.find_by(email: params[:user][:email])

    # Validate credentials using Devise method + admin check
    if @user && @user.valid_password?(params[:user][:password]) && @user.admin?
      sign_in(@user)
      redirect_to admin_dashboard_path, notice: "Welcome, admin!"
    else
      flash[:alert] = "Invalid credentials or not an admin."
      render :login, status: :unauthorized
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to admin_login_path, notice: "Logged out."
  end
end