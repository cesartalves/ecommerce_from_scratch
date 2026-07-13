class AddShippingDetailsToProductsAndOrders < ActiveRecord::Migration[7.2]
  def change
    change_table :products, bulk: true do |t|
      t.integer :weight_grams
      t.decimal :length_cm, precision: 8, scale: 2
      t.decimal :width_cm, precision: 8, scale: 2
      t.decimal :height_cm, precision: 8, scale: 2
    end

    change_table :orders, bulk: true do |t|
      t.decimal :shipping_cost, precision: 10, scale: 2, null: false, default: 0
      t.string :shipping_service
      t.string :shipping_service_code
      t.integer :shipping_days
    end
  end
end
