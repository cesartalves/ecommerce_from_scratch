require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  test "requires administrator access" do
    get admin_orders_path

    assert_redirected_to admin_login_path
  end

  test "renders the order management table" do
    sign_in_admin

    get admin_orders_path

    assert_response :success
    assert_includes response.body, "Consulte pagamentos"
    assert_includes response.body, "admin-table--orders"
    assert_select "a[href=?]", admin_customer_path(orders(:one).user)
    assert_select "a[href=?]", admin_order_path(orders(:one))
  end

  test "shows the shipping address captured for the order" do
    sign_in_admin
    order = orders(:one)
    order.create_shipping_address!(addresses(:one).attributes.slice(*Address::LOCATION_ATTRIBUTES))

    get admin_order_path(order)

    assert_response :success
    assert_select "h2", text: "Endereço de entrega"
    assert_includes response.body, order.shipping_address.street
  end

  private

  def sign_in_admin
    admin = User.create!(
      email: "orders-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )
    post admin_create_session_path, params: {
      user: { email: admin.email, password: "password123" }
    }
  end
end
