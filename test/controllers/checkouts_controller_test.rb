require "test_helper"
require "minitest/mock"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  FakeResponse = Struct.new(:code, :payload) do
    def [](key)
      payload[key]
    end

    def dig(*keys)
      payload.dig(*keys)
    end
  end

  test "marks a PIX order as waiting for payment" do
    user = User.create!(
      email: "pix@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_address!(zipcode: "01001-000")
    order = user.orders.create!(status: :cart, total: 25)
    order.line_items.create!(product: products(:one), quantity: 1, price: products(:one).price)
    response = FakeResponse.new(201, {
      "id" => 123,
      "status" => "pending",
      "point_of_interaction" => {
        "transaction_data" => {
          "qr_code" => "pix-code",
          "qr_code_base64" => "base64-code"
        }
      }
    })
    client = Minitest::Mock.new
    client.expect(:create_payment, response) do |payload|
      payload[:payment_method_id] == "pix" && payload[:transaction_amount] == 9.99
    end
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }

    assert_enqueued_with(job: CheckPaymentStatusJob) do
      MercadoPago::Client.stub(:new, client) do
        post checkouts_path, params: { payment_method: "pix" }
      end
    end

    assert_response :success
    assert_predicate order.reload, :waiting_payment?
    assert_nil order.shipping_service
    assert_equal 0, order.shipping_cost
    assert_nil order.shipping_days
    assert_equal({
      "qr_code" => "pix-code",
      "qr_code_base64" => "base64-code"
    }, order.payments.last.pix_data)
    client.verify
  end

  test "allows checkout without consulting Correios while shipping is disabled" do
    user = User.create!(
      email: "shipping-disabled@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_address!(zipcode: "01001-000")
    order = user.orders.create!(status: :cart, total: 99, shipping_cost: 10, shipping_service: "PAC")
    order.line_items.create!(product: products(:one), quantity: 1, price: products(:one).price)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }

    Correios::Client.stub(:new, -> { flunk "Correios should not be consulted" }) do
      get checkout_path
    end

    assert_response :success
    assert_includes response.body, "Frete temporariamente desativado"
    assert_includes response.body, "value=\"9.99\""
  end

  test "rejects a payment below Mercado Pago's minimum before calling the provider" do
    user = User.create!(
      email: "minimum-payment@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_address!(zipcode: "01001-000")
    product = products(:one)
    product.update!(price: 0.20)
    order = user.orders.create!(status: :cart)
    order.line_items.create!(product: product, quantity: 1, price: product.price)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }

    MercadoPago::Client.stub(:new, -> { flunk "Mercado Pago should not be called" }) do
      post checkouts_path, params: { payment_method: "pix" }
    end

    assert_response :unprocessable_entity
    assert_equal "O valor mínimo para pagamento é R$ 0,50.", response.parsed_body["error"]
    assert_empty order.payments
  end

  test "shows PAC and SEDEX shipping options when shipping is enabled" do
    user = User.create!(
      email: "shipping@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    user.create_address!(zipcode: "01001-000")
    order = user.orders.create!(status: :cart, total: products(:one).price)
    order.line_items.create!(product: products(:one), quantity: 1, price: products(:one).price)
    quotes = [
      Correios::Quote.new(service_code: "03298", service_name: "PAC", price: 18.75, delivery_days: 7),
      Correios::Quote.new(service_code: "03220", service_name: "SEDEX", price: 29.40, delivery_days: 3)
    ]
    shipping_client = Minitest::Mock.new
    shipping_client.expect(:quotes, quotes) do |destination_zipcode:, package:|
      destination_zipcode == "01001-000" && package.weight_grams == 100
    end
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }

    with_shipping_enabled do
      Correios::Client.stub(:new, shipping_client) do
        get checkout_path
      end
    end

    assert_response :success
    assert_includes response.body, "Correios PAC"
    assert_includes response.body, "Correios SEDEX"
    assert_includes response.body, "7 dias úteis"
    shipping_client.verify
  end

  test "sends the selected card installments to Mercado Pago" do
    user = User.create!(email: "installments@example.com", password: "password123")
    user.create_address!(zipcode: "01001-000")
    product = products(:one)
    order = user.orders.create!(status: :cart)
    order.line_items.create!(product: product, quantity: 1, price: product.price)
    response = FakeResponse.new(201, { "id" => 456, "status" => "approved" })
    client = Minitest::Mock.new
    client.expect(:create_payment, response) do |payload, device_id: nil|
      payload[:installments] == 3 &&
        payload[:transaction_amount] == 9.99 &&
        payload.dig(:additional_info, :items, 0, :unit_price) == 9.99
    end
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    MercadoPago::Client.stub(:new, client) do
      post checkouts_path, params: {
        payment_method: "card",
        token: "card-token",
        payment_method_id: "master",
        installments: 3,
        identification_number: "12345678900"
      }
    end

    assert_response :success
    assert_predicate order.reload, :paid?
    client.verify
  end

  test "shows a card rejection without removing the order from the cart" do
    user = User.create!(email: "rejected-card@example.com", password: "password123")
    user.create_address!(zipcode: "01001-000")
    product = products(:one)
    order = user.orders.create!(status: :cart)
    order.line_items.create!(product: product, quantity: 1, price: product.price)
    mercado_pago_response = FakeResponse.new(201, {
      "id" => 789,
      "status" => "rejected",
      "status_detail" => "cc_rejected_other_reason"
    })
    client = Minitest::Mock.new
    client.expect(:create_payment, mercado_pago_response) { |_payload, device_id: nil| device_id.nil? }
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    MercadoPago::Client.stub(:new, client) do
      post checkouts_path, params: {
        payment_method: "card",
        token: "card-token",
        payment_method_id: "master",
        installments: 1,
        identification_number: "12345678900"
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "recusado pelo emissor"
    assert_predicate order.reload, :cart?
    assert_equal "cc_rejected_other_reason", order.payments.last.status_detail
    client.verify
  end

  test "translates an incompatible card payment method response" do
    user = User.create!(email: "invalid-method@example.com", password: "password123")
    user.create_address!(zipcode: "01001-000")
    product = products(:one)
    order = user.orders.create!(status: :cart)
    order.line_items.create!(product: product, quantity: 1, price: product.price)
    mercado_pago_response = FakeResponse.new(400, {
      "message" => "Cannot infer Payment Method",
      "cause" => [ { "code" => 2131 } ]
    })
    client = Minitest::Mock.new
    client.expect(:create_payment, mercado_pago_response) { |_payload, device_id: nil| device_id.nil? }
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    MercadoPago::Client.stub(:new, client) do
      post checkouts_path, params: {
        payment_method: "card",
        token: "card-token",
        payment_method_id: "visa",
        issuer_id: 25,
        installments: 1,
        identification_number: "12345678900"
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "não são compatíveis"
    assert_predicate order.reload, :cart?
    assert_empty order.payments
    client.verify
  end

  private

  def with_shipping_enabled
    previous = ENV["CORREIOS_SHIPPING_ENABLED"]
    ENV["CORREIOS_SHIPPING_ENABLED"] = "true"
    yield
  ensure
    ENV["CORREIOS_SHIPPING_ENABLED"] = previous
  end
end
