require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects visitors to the admin login" do
    get admin_dashboard_path

    assert_redirected_to admin_login_path
  end

  test "renders dashboard metrics for administrators" do
    sign_in_admin("dashboard-admin@example.com")

    get admin_dashboard_path

    assert_response :success
    assert_includes response.body, "Visão geral"
    assert_includes response.body, "Receita confirmada"
    assert_includes response.body, "Pedidos recentes"
  end

  private

  def sign_in_admin(email)
    admin = User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )
    post admin_create_session_path, params: {
      user: { email: admin.email, password: "password123" }
    }
  end
end
