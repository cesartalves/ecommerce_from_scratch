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

  test "completing an order reserves stock only once" do
    order = orders(:one)
    order.update!(status: :cart)
    product = products(:one)
    order.line_items.destroy_all
    order.line_items.create!(product: product, quantity: 2, price: product.price)

    assert_difference -> { product.reload.stock }, -2 do
      order.complete!
    end
    assert_no_difference -> { product.reload.stock } do
      order.complete!
    end
  end

  test "waiting for payment fails atomically when stock is insufficient" do
    order = orders(:one)
    order.update!(status: :cart)
    product = products(:one)
    order.line_items.destroy_all
    order.line_items.create!(product: product, quantity: product.stock + 1, price: product.price)

    assert_raises(ActiveRecord::RecordInvalid) { order.wait_for_payment! }
    assert_predicate order.reload, :cart?
    assert_nil order.stock_reserved_at
  end
end
