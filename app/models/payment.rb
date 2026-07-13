class Payment < ApplicationRecord
  PENDING_STATUSES = %w[pending authorized in_process in_mediation].freeze

  belongs_to :order

  validates :external_id, presence: true, uniqueness: true
  validates :payment_method, :status, presence: true

  def approved?
    status == "approved"
  end

  def awaiting_confirmation?
    status.in?(PENDING_STATUSES)
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
