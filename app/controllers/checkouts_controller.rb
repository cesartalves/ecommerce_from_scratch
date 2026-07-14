class CheckoutsController < ApplicationController
  MINIMUM_PAYMENT_AMOUNT = BigDecimal("0.50")

  before_action :authenticate_user!
  before_action :confirm_address, if: :address_missing?

  def index
    @order = current_user.cart_order
    unless @order.stock_available?
      redirect_to cart_path, alert: "Revise o carrinho: um ou mais produtos estão sem estoque suficiente."
      return
    end
    @public_key = ENV["MP_PUBLIC_KEY"]
    load_shipping_quotes
    @minimum_payment_amount = MINIMUM_PAYMENT_AMOUNT
  end

  def create
    @order = current_user.cart_order
    return render_stock_error unless @order.stock_available?
    return render_shipping_error unless apply_shipping
    return render_minimum_amount_error if @order.total < MINIMUM_PAYMENT_AMOUNT

    client = MercadoPago::Client.new

    case params[:payment_method]
    when "card"
      installments = params[:installments].to_i
      return render_installments_error unless installments.between?(1, 24)

      payload = {
        transaction_amount: @order.total.to_f,
        token: params[:token],
        description: "Pedido ##{@order.id}",
        installments: installments,
        payment_method_id: params[:payment_method_id],
        payer: {
          email: current_user.email,
          identification: {
            type: "CPF",
            number: params[:identification_number]
          },
          first_name: customer_first_name,
          last_name: customer_last_name
        },
        additional_info: payment_additional_info
      }
      payload[:issuer_id] = params[:issuer_id].to_i if params[:issuer_id].present?

      response = client.create_payment(payload, device_id: params[:device_id].presence)

      return render_payment_error(response) unless response.code == 201

      payment = create_payment_from(response, "card")
      process_payment_status(payment)

      if payment.rejected?
        return render json: { error: payment.rejection_message }, status: :unprocessable_entity
      end

      unless payment.approved? || payment.awaiting_confirmation?
        return render json: { error: "O Mercado Pago retornou um estado de pagamento inesperado. Tente novamente." },
                      status: :unprocessable_entity
      end

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
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.warn("Checkout stock reservation failed for order #{@order.id}: #{error.message}")
    render_stock_error
  end

  private

  def load_shipping_quotes
    @subtotal = @order.items_total
    @shipping_enabled = shipping_enabled?
    unless @shipping_enabled
      @shipping_quotes = []
      @display_total = @subtotal
      return
    end

    @shipping_quotes = shipping_client.quotes(
      destination_zipcode: current_user.address.zipcode,
      package: @order.shipping_package
    )
    @selected_shipping_code = if @shipping_quotes.any? { |quote| quote.service_code == @order.shipping_service_code }
      @order.shipping_service_code
    else
      @shipping_quotes.first&.service_code
    end
    selected_quote = @shipping_quotes.find { |quote| quote.service_code == @selected_shipping_code }
    @display_total = @subtotal + (selected_quote&.price || 0)
  rescue Correios::Error => error
    @shipping_quotes = []
    @shipping_error = error.message
    @display_total = @subtotal || @order.items_total
  end

  def apply_shipping
    unless shipping_enabled?
      @order.recalculate!
      return true
    end

    quote = shipping_client.quote(
      service_code: params[:shipping_service].to_s,
      destination_zipcode: current_user.address.zipcode,
      package: @order.shipping_package
    )
    @order.apply_shipping!(quote)
    true
  rescue Correios::Error => error
    @shipping_error = error.message
    false
  end

  def shipping_client
    @shipping_client ||= Correios::Client.new
  end

  def shipping_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("CORREIOS_SHIPPING_ENABLED", "false"))
  end

  def create_payment_from(response, payment_method, pix_data: {})
    @order.payments.create!(
      external_id: response["id"].to_s,
      payment_method: payment_method,
      status: response["status"],
      status_detail: response["status_detail"],
      pix_data: pix_data
    )
  end

  def process_payment_status(payment)
    if payment.approved?
      @order.complete!
    elsif payment.awaiting_confirmation?
      @order.wait_for_payment!
      CheckPaymentStatusJob.perform_later(payment)
    end
  end

  def render_payment_error(response)
    render json: { error: mercado_pago_error_message(response) },
           status: :unprocessable_entity
  end

  def mercado_pago_error_message(response)
    cause_code = response.dig("cause", 0, "code")
    return "O cartão e a opção de parcelamento não são compatíveis. Confira o cartão e selecione novamente as parcelas." if cause_code == 2131

    response["message"] || "Não foi possível processar o pagamento."
  end

  def render_shipping_error
    render json: { error: @shipping_error || "Selecione uma forma de entrega." },
           status: :unprocessable_entity
  end

  def render_stock_error
    render json: { error: "Um ou mais produtos não possuem estoque suficiente. Revise o carrinho." },
           status: :unprocessable_entity
  end

  def render_minimum_amount_error
    render json: {
      error: "O valor mínimo para pagamento é R$ 0,50."
    }, status: :unprocessable_entity
  end

  def render_installments_error
    render json: { error: "Selecione uma opção de parcelamento válida." },
           status: :unprocessable_entity
  end

  def payment_additional_info
    {
      items: @order.line_items.includes(:product).map do |line_item|
        {
          id: line_item.product_id.to_s,
          title: line_item.product.name,
          description: line_item.product.description.to_s.truncate(200),
          category_id: "collectibles",
          quantity: line_item.quantity,
          unit_price: (line_item.price || line_item.product.price).to_f
        }
      end,
      shipments: {
        receiver_address: {
          zip_code: current_user.address.zipcode,
          street_name: current_user.address.street,
          street_number: current_user.address.number
        }
      }
    }
  end

  def customer_first_name
    current_user.name.to_s.split.first.to_s
  end

  def customer_last_name
    current_user.name.to_s.split.drop(1).join(" ")
  end

  def address_missing?
    current_user.present? && current_user.address.nil?
  end



  def confirm_address
    redirect_to new_address_path, alert: "Por favor, cadastre seu endereço antes de continuar."
  end
end
