class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :payment_method, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :payments, :external_id, unique: true
  end
end
