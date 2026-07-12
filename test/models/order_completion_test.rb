require "test_helper"

class OrderCompletionTest < ActiveSupport::TestCase
  test "completing an order creates a new empty cart" do
    order = orders(:one)
    order.update!(status: :cart)

    order.complete!

    new_cart = order.user.cart_order
    assert_predicate order.reload, :paid?
    assert_not_equal order, new_cart
    assert_predicate new_cart, :cart?
    assert_empty new_cart.line_items
  end
end
