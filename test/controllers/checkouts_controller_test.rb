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
    user.create_address!
    order = user.orders.create!(status: :cart, total: 25)
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
    client.expect(:create_payment, response) { |payload| payload[:payment_method_id] == "pix" }
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
    assert_equal({
      "qr_code" => "pix-code",
      "qr_code_base64" => "base64-code"
    }, order.payments.last.pix_data)
    client.verify
  end
end
