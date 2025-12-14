class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def index 
    @public_key = Rails.application.credentials.dig(:mercado_pago, :public_key)
  end
  
  def create
    order = current_user.orders.pending.last

    case params[:payment_method]
    when "card"
      payment = MercadoPago::SDK.new(
        Rails.application.credentials.dig(:mercado_pago, :access_token)
      ).payment.create(card_payload(order))

    when "pix"
      payment = MercadoPago::SDK.new(
        Rails.application.credentials.dig(:mercado_pago, :access_token)
      ).payment.create(pix_payload(order))
    end

    if payment["status"] == "approved" || payment["status"] == "pending"
      render json: {
        success: true,
        redirect_url: payment["point_of_interaction"]&.dig("transaction_data", "ticket_url") ||
                      success_path
      }
    else
      render json: { success: false, error: "Pagamento recusado" }, status: 422
    end
  end

  private

  def card_payload(order)
    {
      transaction_amount: order.total.to_f,
      token: params[:token],
      installments: params[:installments],
      issuer_id: params[:issuer_id],
      payment_method_id: "visa",
      payer: params[:payer]
    }
  end

  def pix_payload(order)
    {
      transaction_amount: order.total.to_f,
      payment_method_id: "pix",
      payer: {
        email: current_user.email
      }
    }
  end
end
