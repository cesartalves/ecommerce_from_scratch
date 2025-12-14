class CreateLineItems < ActiveRecord::Migration[7.2]
  def change
    create_table :line_items do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.references :order, null: false, foreign_key: true
      t.decimal :price

      t.timestamps
    end
  end
end
