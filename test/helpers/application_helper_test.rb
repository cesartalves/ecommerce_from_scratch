require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "translates known order statuses" do
    order = Struct.new(:status).new("waiting_payment")

    assert_equal "Aguardando pagamento", order_status_label(order)
  end

  test "handles an order status that cannot be deserialized" do
    order = Struct.new(:status).new(nil)

    assert_equal "Status desconhecido", order_status_label(order)
  end
end
