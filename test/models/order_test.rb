require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "stores statuses as strings" do
    order = orders(:one)

    order.waiting_payment!

    assert_equal "waiting_payment", order.reload.status
    assert_equal "waiting_payment", order.status_before_type_cast
  end
end
