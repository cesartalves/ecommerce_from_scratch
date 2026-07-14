class Payment < ApplicationRecord
  PENDING_STATUSES = %w[pending authorized in_process in_mediation].freeze
  REJECTION_MESSAGES = {
    "cc_rejected_bad_filled_card_number" => "Confira o número do cartão.",
    "cc_rejected_bad_filled_date" => "Confira a data de validade do cartão.",
    "cc_rejected_bad_filled_security_code" => "Confira o código de segurança do cartão.",
    "cc_rejected_call_for_authorize" => "Autorize o pagamento com o banco emissor e tente novamente.",
    "cc_rejected_card_disabled" => "O cartão está desabilitado. Entre em contato com o banco emissor.",
    "cc_rejected_duplicated_payment" => "Este pagamento parece duplicado. Aguarde alguns minutos antes de tentar novamente.",
    "cc_rejected_insufficient_amount" => "O cartão não possui limite suficiente para esta compra.",
    "cc_rejected_invalid_installments" => "A quantidade de parcelas escolhida não foi aceita.",
    "cc_rejected_max_attempts" => "O limite de tentativas foi atingido. Use outro cartão ou tente mais tarde.",
    "cc_rejected_high_risk" => "O pagamento não passou pela validação de segurança. Tente outro meio de pagamento.",
    "cc_rejected_other_reason" => "O pagamento foi recusado pelo emissor. Tente outro cartão ou entre em contato com o banco."
  }.freeze

  belongs_to :order

  validates :external_id, presence: true, uniqueness: true
  validates :payment_method, :status, presence: true

  def approved?
    status == "approved"
  end

  def awaiting_confirmation?
    status.in?(PENDING_STATUSES)
  end

  def rejected?
    status == "rejected"
  end

  def rejection_message
    REJECTION_MESSAGES.fetch(status_detail, "O pagamento não foi aprovado. Confira os dados ou tente outro cartão.")
  end

  def pix?
    payment_method == "pix"
  end

  def pix_qr_code
    pix_data["qr_code"]
  end

  def pix_qr_code_base64
    pix_data["qr_code_base64"]
  end
end
