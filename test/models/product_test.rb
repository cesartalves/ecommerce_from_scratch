require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "requires parcel weight and dimensions" do
    product = Product.new(name: "Sem embalagem", price: 10)

    assert_not product.valid?
    assert product.errors.added?(:weight_grams, :not_a_number, value: nil)
    assert product.errors.added?(:length_cm, :not_a_number, value: nil)
    assert product.errors.added?(:width_cm, :not_a_number, value: nil)
    assert product.errors.added?(:height_cm, :not_a_number, value: nil)
  end
end
