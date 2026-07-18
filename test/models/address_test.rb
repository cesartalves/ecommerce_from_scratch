require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "must belong to either a user or an order" do
    address = Address.new

    assert_not address.valid?
    assert_includes address.errors[:base], "O endereço deve pertencer a um usuário ou pedido"
  end

  test "cannot belong to both a user and an order" do
    address = addresses(:one)
    address.order = orders(:one)

    assert_not address.valid?
  end
end
