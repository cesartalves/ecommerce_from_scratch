module ApplicationHelper
  ORDER_STATUS_LABELS = {
    "pending" => "Pendente",
    "waiting_payment" => "Aguardando pagamento",
    "paid" => "Pago",
    "cancelled" => "Cancelado",
    "cart" => "Carrinho"
  }.freeze

  def order_status_label(order)
    ORDER_STATUS_LABELS.fetch(order.status, order.status.humanize)
  end

  def order_status_badge_class(order)
    {
      "paid" => "admin-badge--success",
      "waiting_payment" => "admin-badge--warning",
      "cancelled" => "admin-badge--danger",
      "pending" => "admin-badge--info"
    }.fetch(order.status, "admin-badge--neutral")
  end
end
