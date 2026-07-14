class LineItem < ApplicationRecord
  belongs_to :product
  belongs_to :order

  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
