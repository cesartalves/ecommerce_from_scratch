require "test_helper"

class Correios::PackageTest < ActiveSupport::TestCase
  test "combines product parcels using quantity" do
    order = orders(:one)
    order.line_items.create!(product: products(:two), quantity: 2, price: products(:two).price)

    package = Correios::Package.from_line_items(order.line_items.includes(:product))

    assert_equal 500, package.weight_grams
    assert_equal 20, package.length_cm
    assert_equal 15, package.width_cm
    assert_equal 8, package.height_cm
  end

  test "rejects products without shipping data" do
    product = products(:one)
    product.update_column(:weight_grams, nil)

    error = assert_raises(Correios::Error) do
      Correios::Package.from_line_items(orders(:one).line_items.includes(:product))
    end

    assert_includes error.message, product.name
  end
end
