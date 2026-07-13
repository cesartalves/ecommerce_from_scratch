class Admin::LoginController < ApplicationController
  layout "admin"

  def login
    @user = User.new
  end

  def create
    @user = User.find_by(email: params[:user][:email])

    if @user && @user.valid_password?(params[:user][:password]) && @user.admin?
      sign_in(@user)
      redirect_to admin_dashboard_path, notice: "Bem-vindo ao painel administrativo."
    else
      flash.now[:alert] = "E-mail ou senha inválidos, ou usuário sem acesso administrativo."
      render :login, status: :unauthorized
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to admin_login_path, notice: "Sessão encerrada com sucesso."
  end
end
