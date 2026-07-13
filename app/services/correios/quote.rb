class Correios::Quote
  attr_reader :service_code, :service_name, :price, :delivery_days

  def initialize(service_code:, service_name:, price:, delivery_days:)
    @service_code = service_code
    @service_name = service_name
    @price = price
    @delivery_days = delivery_days
  end
end
