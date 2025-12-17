class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: {
    user: 0,
    admin: 1,
    editor: 2
  }

  has_many :orders
  has_one :address, dependent: :destroy

  def cart_order
    orders.find_or_create_by(status: :cart)
  end
end
