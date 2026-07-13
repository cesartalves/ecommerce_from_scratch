class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :confirm_address, if: :address_missing?

  def index
    @order = current_user.cart_order
    @public_key = ENV["MP_PUBLIC_KEY"]
  end

  def create
    @order = current_user.cart_order
    client = MercadoPago::Client.new

    case params[:payment_method]
    when "card"
      payload = {
        transaction_amount: @order.total.to_f,
        token: params[:token],
        description: "Pedido ##{@order.id}",
        installments: 1,
        payment_method_id: params[:payment_method_id],
        payer: {
          email: current_user.email,
          identification: {
            type: "CPF",
            number: params[:identification_number]
          }
        }
      }
      payload[:issuer_id] = params[:issuer_id].to_i if params[:issuer_id].present?

      response = client.create_payment(payload)

      return render_payment_error(response) unless response.code == 201

      payment = create_payment_from(response, "card")
      process_payment_status(payment)

      render json: { status: payment.status }

    when "pix"
      response = client.create_payment(
        transaction_amount: @order.total.to_f,
        description: "Pedido ##{@order.id}",
        payment_method_id: "pix",
        payer: {
          email: current_user.email
        }
      )

      return render_payment_error(response) unless response.code == 201

      transaction_data = response.dig("point_of_interaction", "transaction_data") || {}
      payment = create_payment_from(response, "pix", pix_data: transaction_data)
      process_payment_status(payment)

      render json: {
        qr_code: payment.pix_qr_code,
        qr_code_base64: payment.pix_qr_code_base64
      }
    else
      render json: { error: "Método de pagamento inválido." }, status: :unprocessable_entity
    end
  end

  private

  def create_payment_from(response, payment_method, pix_data: {})
    @order.payments.create!(
      external_id: response["id"].to_s,
      payment_method: payment_method,
      status: response["status"],
      pix_data: pix_data
    )
  end

  def process_payment_status(payment)
    if payment.approved?
      @order.complete!
    elsif payment.awaiting_confirmation?
      @order.waiting_payment! if payment.payment_method == "pix"
      CheckPaymentStatusJob.perform_later(payment)
    end
  end

  def render_payment_error(response)
    render json: { error: response["message"] || "Não foi possível processar o pagamento." },
           status: :unprocessable_entity
  end

  def address_missing?
    current_user.present? && current_user.address.nil?
  end



  def confirm_address
    redirect_to new_address_path, alert: "Por favor, cadastre seu endereço antes de continuar."
  end
end
