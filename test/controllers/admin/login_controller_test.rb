require "test_helper"

class Admin::LoginControllerTest < ActionDispatch::IntegrationTest
  test "renders the styled admin login" do
    get admin_login_path

    assert_response :success
    assert_includes response.body, "Bem-vindo de volta"
    assert_includes response.body, "admin-login-card"
  end

  test "signs in an administrator" do
    admin = create_admin

    post admin_create_session_path, params: {
      user: { email: admin.email, password: "password123" }
    }

    assert_redirected_to admin_dashboard_path
  end

  private

  def create_admin
    User.create!(
      email: "admin-login@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )
  end
end
