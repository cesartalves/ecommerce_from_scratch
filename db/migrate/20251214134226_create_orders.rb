class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end