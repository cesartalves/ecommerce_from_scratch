require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "stores statuses as strings" do
    order = orders(:one)

    order.waiting_payment!

    assert_equal "waiting_payment", order.reload.status
    assert_equal "waiting_payment", order.status_before_type_cast
  end

  test "applies shipping to the order total" do
    order = orders(:one)
    quote = Correios::Quote.new(
      service_code: "03220",
      service_name: "SEDEX",
      price: BigDecimal("12.50"),
      delivery_days: 3
    )

    order.apply_shipping!(quote)

    assert_equal BigDecimal("22.49"), order.total
    assert_equal BigDecimal("12.50"), order.shipping_cost
    assert_equal "SEDEX", order.shipping_service
    assert_equal "03220", order.shipping_service_code
    assert_equal 3, order.shipping_days
  end

  test "recalculation clears a stale shipping quote" do
    order = orders(:one)
    order.update!(shipping_cost: 10, shipping_service: "PAC", total: 19.99)

    order.recalculate!

    assert_equal BigDecimal("9.99"), order.total
    assert_equal 0, order.shipping_cost
    assert_nil order.shipping_service
  end
end
