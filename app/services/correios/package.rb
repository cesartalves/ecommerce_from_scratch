class Correios::Package
  attr_reader :weight_grams, :length_cm, :width_cm, :height_cm

  def self.from_line_items(line_items)
    items = line_items.to_a
    raise Correios::Error, "O carrinho está vazio." if items.empty?

    products_without_shipping_data = items.filter_map do |line_item|
      product = line_item.product
      product.name unless [
        product.weight_grams,
        product.length_cm,
        product.width_cm,
        product.height_cm
      ].all?(&:present?)
    end

    if products_without_shipping_data.any?
      names = products_without_shipping_data.to_sentence
      raise Correios::Error, "Dados de envio ausentes para: #{names}."
    end

    new(
      weight_grams: items.sum { |item| item.product.weight_grams * item.quantity },
      length_cm: items.map { |item| item.product.length_cm }.max,
      width_cm: items.map { |item| item.product.width_cm }.max,
      height_cm: items.sum { |item| item.product.height_cm * item.quantity }
    )
  end

  def initialize(weight_grams:, length_cm:, width_cm:, height_cm:)
    @weight_grams = weight_grams
    @length_cm = length_cm
    @width_cm = width_cm
    @height_cm = height_cm
  end

  def to_query
    {
      psObjeto: weight_grams.to_i,
      tpObjeto: 2,
      comprimento: decimal_string(length_cm),
      largura: decimal_string(width_cm),
      altura: decimal_string(height_cm)
    }
  end

  private

  def decimal_string(value)
    format("%.2f", value)
  end
end
