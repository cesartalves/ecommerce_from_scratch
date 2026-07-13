require "test_helper"

class Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    admin = User.create!(
      email: "products-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )
    post admin_create_session_path, params: {
      user: { email: admin.email, password: "password123" }
    }
  end

  test "renders the product catalog" do
    get admin_products_path

    assert_response :success
    assert_includes response.body, "Gerencie as peças"
    assert_includes response.body, "admin-table--products"
  end

  test "renders the shared product form" do
    get new_admin_product_path

    assert_response :success
    assert_includes response.body, "Informações do produto"
    assert_includes response.body, "Nome do produto"
    assert_includes response.body, "Peso (gramas)"
    assert_includes response.body, "Comprimento (cm)"
  end
end
