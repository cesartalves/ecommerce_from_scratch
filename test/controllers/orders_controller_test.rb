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

  test "shows paid and waiting payment orders only" do
    user = create_user("orders@example.com")
    paid_order = user.orders.create!(status: :paid, total: 10)
    waiting_order = user.orders.create!(status: :waiting_payment, total: 20)
    waiting_order.payments.create!(
      external_id: "pix-payment-123",
      payment_method: "pix",
      status: "pending",
      pix_data: {
        "qr_code" => "pix-copy-and-paste-code",
        "qr_code_base64" => "pix-base64-image"
      }
    )
    pending_order = user.orders.create!(status: :pending, total: 30)
    cancelled_order = user.orders.create!(status: :cancelled, total: 40)
    cart_order = user.orders.create!(status: :cart, total: 50)
    sign_in(user)

    get orders_path

    assert_response :success
    assert_includes response.body, "Pedido ##{paid_order.id}</strong>"
    assert_includes response.body, "Pedido ##{waiting_order.id}</strong>"
    assert_includes response.body, "Pago"
    assert_includes response.body, "Aguardando pagamento"
    assert_includes response.body, "PIX copia e cola"
    assert_includes response.body, "pix-copy-and-paste-code"
    assert_includes response.body, "data:image/png;base64,pix-base64-image"
    assert_not_includes response.body, "waiting_payment"
    assert_not_includes response.body, "Pedido ##{pending_order.id}</strong>"
    assert_not_includes response.body, "Pedido ##{cancelled_order.id}</strong>"
    assert_not_includes response.body, "Pedido ##{cart_order.id}</strong>"
  end

  private

  def create_user(email)
    User.create!(
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end
