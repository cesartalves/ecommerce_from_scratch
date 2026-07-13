require "test_helper"
require "minitest/mock"

class CheckPaymentStatusJobTest < ActiveJob::TestCase
  FakeResponse = Struct.new(:code, :payload) do
    def success?
      code.between?(200, 299)
    end

    def [](key)
      payload[key]
    end
  end

  setup do
    @order = orders(:one)
    @order.update!(status: :waiting_payment)
    @payment = Payment.create!(
      order: @order,
      external_id: "123456789",
      payment_method: "pix",
      status: "pending"
    )
  end

  test "marks the payment and order as paid when Mercado Pago approves it" do
    client = Object.new
    client.define_singleton_method(:payment) do |_external_id|
      FakeResponse.new(200, { "status" => "approved" })
    end

    MercadoPago::Client.stub(:new, client) do
      CheckPaymentStatusJob.perform_now(@payment)
    end

    assert_equal "approved", @payment.reload.status
    assert_predicate @order.reload, :paid?
    assert_predicate @order.user.cart_order, :cart?
    assert_not_equal @order, @order.user.cart_order
  end

  test "schedules another check while the payment is pending" do
    client = Object.new
    client.define_singleton_method(:payment) do |_external_id|
      FakeResponse.new(200, { "status" => "pending" })
    end

    assert_enqueued_jobs 1, only: CheckPaymentStatusJob do
      MercadoPago::Client.stub(:new, client) do
        CheckPaymentStatusJob.perform_now(@payment)
      end
    end

    assert_equal "pending", @payment.reload.status
    assert_predicate @order.reload, :waiting_payment?
  end

  test "does not schedule another check for a rejected payment" do
    client = Object.new
    client.define_singleton_method(:payment) do |_external_id|
      FakeResponse.new(200, { "status" => "rejected" })
    end

    assert_no_enqueued_jobs only: CheckPaymentStatusJob do
      MercadoPago::Client.stub(:new, client) do
        CheckPaymentStatusJob.perform_now(@payment)
      end
    end

    assert_equal "rejected", @payment.reload.status
    assert_predicate @order.reload, :waiting_payment?
  end
end
