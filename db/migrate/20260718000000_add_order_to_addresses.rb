class AddOrderToAddresses < ActiveRecord::Migration[7.2]
  def change
    change_column_null :addresses, :user_id, true
    add_reference :addresses, :order, foreign_key: true, index: { unique: true }
    add_check_constraint :addresses,
                         "(user_id IS NOT NULL AND order_id IS NULL) OR (user_id IS NULL AND order_id IS NOT NULL)",
                         name: "addresses_belong_to_user_or_order"
  end
end
