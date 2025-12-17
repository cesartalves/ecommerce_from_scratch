class CheckoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :confirm_address, if: :address_missing?

  def index 
    @order = current_user.cart_order
    @public_key = ENV['MP_PUBLIC_KEY']
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

  private

  def address_missing?
    current_user.present? && current_user.address.nil?
  end



  def confirm_address
    redirect_to new_address_path, alert: "Por favor, cadastre seu endereço antes de continuar."
  end
end
