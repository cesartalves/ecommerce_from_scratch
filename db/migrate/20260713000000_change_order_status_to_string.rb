class ChangeOrderStatusToString < ActiveRecord::Migration[7.2]
  def up
    change_column_default :orders, :status, from: 0, to: nil
    change_column :orders, :status, :string,
                  null: false,
                  using: <<~SQL.squish
                    CASE status
                      WHEN 0 THEN 'pending'
                      WHEN 1 THEN 'paid'
                      WHEN 2 THEN 'cancelled'
                      WHEN 3 THEN 'cart'
                    END
                  SQL
    change_column_default :orders, :status, from: nil, to: "pending"
  end

  def down
    change_column_default :orders, :status, from: "pending", to: nil
    change_column :orders, :status, :integer,
                  null: false,
                  using: <<~SQL.squish
                    CASE status
                      WHEN 'pending' THEN 0
                      WHEN 'waiting_payment' THEN 0
                      WHEN 'paid' THEN 1
                      WHEN 'cancelled' THEN 2
                      WHEN 'cart' THEN 3
                    END
                  SQL
    change_column_default :orders, :status, from: nil, to: 0
  end
end
