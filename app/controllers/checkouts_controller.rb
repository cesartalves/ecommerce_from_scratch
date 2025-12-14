class CheckoutsController < ApplicationController
  before_action :authenticate_user!

  def index 
    @order = current_user.cart_order
    @public_key = Rails.application.credentials.dig(:mercado_pago, :public_key)
  end
  
  def create
    @order = current_user.cart_order

    case params[:payment_method]
    when "card"
      client = MercadoPago::Client.new

      response = client.create_payment(
        transaction_amount: @order.total.to_f,
        token: params[:token],
        description: "Pedido ##{@order.id}",
        installments: 1,
        payment_method_id: 'master',
        payer: {
          email: current_user.email
        }
      )

      if response.code == 201
        @order.paid!
      end

    when "pix"
      client = MercadoPago::Client.new

      response = client.create_payment(
        transaction_amount: @order.total.to_f,
        description: "Pedido ##{@order.id}",
        payment_method_id: "pix",
        payer: {
          email: current_user.email
        }
      )

      if response.code == 201
        qr_code = response['point_of_interaction']['transaction_data']['qr_code']
        qr_code_base64 = response['point_of_interaction']['transaction_data']['qr_code_base64']

        render json: { qr_code: qr_code, qr_code_base64: qr_code_base64 }
      end 
    end
  end 
end
