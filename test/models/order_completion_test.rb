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

  test "completing an order copies the customer address as an immutable shipping snapshot" do
    order = orders(:one)
    order.update!(status: :cart)
    customer_address = order.user.address

    assert_difference "Address.count", 1 do
      order.complete!
    end

    shipping_address = order.reload.shipping_address
    assert_equal customer_address.attributes.slice(*Address::LOCATION_ATTRIBUTES),
                 shipping_address.attributes.slice(*Address::LOCATION_ATTRIBUTES)
    assert_nil shipping_address.user_id

    customer_address.update!(street: "Novo endereço")
    assert_not_equal customer_address.street, shipping_address.reload.street
  end

  test "completing the same order twice creates only one shipping address" do
    order = orders(:one)
    order.update!(status: :cart)

    order.complete!

    assert_no_difference "Address.count" do
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
