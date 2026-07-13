class AddPixDataToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :pix_data, :jsonb, null: false, default: {}
  end
end
