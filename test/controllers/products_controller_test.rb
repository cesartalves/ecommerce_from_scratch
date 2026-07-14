require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "product cards include an add to cart button" do
    get products_path

    assert_response :success

    Product.find_each do |product|
      assert_select ".products-card form[action=?][method=post]",
        add_product_path(product_id: product.id) do
        assert_select "button", text: "Adicionar ao Carrinho"
      end
    end
  end

  test "does not list products without stock" do
    products(:one).update!(stock: 0)

    get products_path

    assert_response :success
    assert_select "h3", text: products(:one).name, count: 0
  end
end
