class AddStatusDetailToPayments < ActiveRecord::Migration[7.2]
  def change
    add_column :payments, :status_detail, :string
  end
end
