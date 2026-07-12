require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to products after signing in" do
    user = User.create!(
      email: "customer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }

    assert_redirected_to products_path
  end
end
