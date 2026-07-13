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
end
