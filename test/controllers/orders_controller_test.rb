require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "redirects to cart after adding a product" do
    user = User.create!(
      email: "shopper@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    product = products(:one)

    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
    post add_product_path(product_id: product.id)

    assert_redirected_to cart_path
    assert_equal 1, user.cart_order.line_items.find_by!(product: product).quantity
  end
end
