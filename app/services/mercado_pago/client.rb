# frozen_string_literal: true

class MercadoPago::Client
  include HTTParty
  base_uri "https://api.mercadopago.com"

  def initialize
    @headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type"  => "application/json",
      "X-Idempotency-Key" => SecureRandom.uuid
    }
  end

  def create_payment(payload)
    self.class.post(
      "/v1/payments",
      headers: @headers,
      body: payload.to_json
    )
  end

  private

  def access_token
    ENV['MP_ACCESS_TOKEN']
  end
end