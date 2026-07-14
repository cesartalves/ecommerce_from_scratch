class Product < ApplicationRecord
  has_one_attached :image

  validates :price, numericality: { greater_than: 0 }
  validates :name, uniqueness: true
  validates :weight_grams, numericality: { only_integer: true, greater_than: 0 }
  validates :length_cm, :width_cm, :height_cm, numericality: { greater_than: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :in_stock, -> { where("stock > 0") }

  def in_stock?
    stock.positive?
  end

  def self.ransackable_attributes(auth_object = nil)
  [
    "name",
    "description"
  ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "image_attachment", "image_blob" ]
  end
end
