class Address < ApplicationRecord
  LOCATION_ATTRIBUTES = %w[street number neighborhood city state zipcode country].freeze

  belongs_to :user, optional: true
  belongs_to :order, optional: true

  validate :belongs_to_exactly_one_owner

  private

  def belongs_to_exactly_one_owner
    return if user_id.present? ^ order_id.present?

    errors.add(:base, "O endereço deve pertencer a um usuário ou pedido")
  end
end
