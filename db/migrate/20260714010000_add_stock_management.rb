class AddStockManagement < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :stock, :integer, null: false, default: 0
    add_check_constraint :products, "stock >= 0", name: "products_stock_non_negative"

    add_column :orders, :stock_reserved_at, :datetime
  end
end
