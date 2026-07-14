require "test_helper"

class Admin::CustomersControllerTest < ActionDispatch::IntegrationTest
  test "shows customer contact and address details to administrators" do
    admin = User.create!(email: "customer-admin@example.com", password: "password123", role: :admin)
    post admin_create_session_path, params: { user: { email: admin.email, password: "password123" } }
    customer = users(:one)
    customer.update!(name: "Cliente Exemplo")

    get admin_customer_path(customer)

    assert_response :success
    assert_includes response.body, "Cliente Exemplo"
    assert_includes response.body, customer.email
    assert_includes response.body, customer.address.street
    assert_includes response.body, "Pedido ##{orders(:one).id}"
  end
end
