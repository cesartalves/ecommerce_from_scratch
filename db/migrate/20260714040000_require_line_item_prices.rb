class RequireLineItemPrices < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL.squish
      UPDATE line_items
      SET price = products.price
      FROM products
      WHERE line_items.product_id = products.id
        AND line_items.price IS NULL
    SQL

    change_column_null :line_items, :price, false
  end

  def down
    change_column_null :line_items, :price, true
  end
end
