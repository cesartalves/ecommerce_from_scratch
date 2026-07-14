require "test_helper"

class CartControllerTest < ActionDispatch::IntegrationTest
  test "cart shows product image area and links its name to the product" do
    user = User.create!(email: "cart@example.com", password: "password123", password_confirmation: "password123")
    order = user.orders.create!(status: :cart)
    product = products(:one)
    order.line_items.create!(product: product, quantity: 1, price: product.price)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    get cart_path

    assert_response :success
    assert_select "a.cart-product-image[href=?]", product_path(product)
    assert_select "a.cart-product-name[href=?]", product_path(product), text: product.name
  end
end
