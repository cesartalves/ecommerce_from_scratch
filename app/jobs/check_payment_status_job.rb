class CheckPaymentStatusJob < ApplicationJob
  queue_as :default

  POLLING_INTERVAL = 10.seconds
  MAX_ATTEMPTS = 180
  discard_on ActiveRecord::RecordNotFound

  def perform(payment, attempt = 1)
    response = MercadoPago::Client.new.payment(payment.external_id)
    raise "Mercado Pago returned HTTP #{response.code}" unless response.success?

    status = response["status"]
    payment.update!(status: status)

    if payment.approved?
      payment.order.complete!
    elsif payment.awaiting_confirmation? && attempt < MAX_ATTEMPTS
      self.class.set(wait: POLLING_INTERVAL).perform_later(payment, attempt + 1)
    end
  end
end
