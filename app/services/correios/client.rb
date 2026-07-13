class Correios::Client
  PRICE_BASE_URL = "https://api.correios.com.br/preco/v1".freeze
  DEADLINE_BASE_URL = "https://api.correios.com.br/prazo/v1".freeze

  def initialize(
    token_provider: Correios::TokenProvider.new,
    origin_zipcode: ENV.fetch("CORREIOS_ORIGIN_ZIP", "17509031"),
    http: HTTParty
  )
    @token_provider = token_provider
    @origin_zipcode = normalize_zipcode(origin_zipcode)
    @http = http
  end

  def quotes(destination_zipcode:, package:)
    errors = []
    results = service_codes.filter_map do |service_code|
      quote(service_code:, destination_zipcode:, package:)
    rescue Correios::Error => error
      errors << error
      nil
    end

    raise(errors.last || Correios::Error.new("Nenhum frete disponível para este CEP.")) if results.empty?

    results.sort_by(&:price)
  end

  def quote(service_code:, destination_zipcode:, package:)
    service_name = services[service_code]
    raise Correios::Error, "Serviço de entrega inválido." unless service_name
    destination = normalize_zipcode(destination_zipcode)
    price_data = get(
      "#{price_base_url}/nacional/#{service_code}",
      package.to_query.merge(cepOrigem: @origin_zipcode, cepDestino: destination)
    )
    deadline_data = get(
      "#{deadline_base_url}/nacional/#{service_code}",
      {
        cepOrigem: @origin_zipcode,
        cepDestino: destination
      }
    )

    Correios::Quote.new(
      service_code: service_code,
      service_name: service_name,
      price: parse_price(price_data.fetch("pcFinal")),
      delivery_days: Integer(deadline_data.fetch("prazoEntrega"))
    )
  rescue KeyError, ArgumentError, TypeError
    raise Correios::Error, "Os Correios retornaram uma cotação inválida."
  end

  private

  def services
    {
      ENV.fetch("CORREIOS_PAC_CODE", "03298") => "PAC",
      ENV.fetch("CORREIOS_SEDEX_CODE", "03220") => "SEDEX"
    }
  end

  def service_codes
    services.keys
  end

  def get(url, query, retry_auth: true)
    response = @http.get(
      url,
      headers: {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{@token_provider.token}"
      },
      query: query,
      timeout: 8
    )
    data = response.parsed_response
    return data if response.success? && data.is_a?(Hash)

    if retry_auth && [ 401, 403 ].include?(response_status(response))
      @token_provider.invalidate!
      return get(url, query, retry_auth: false)
    end

    message = if data.is_a?(Hash)
      data["msgErro"] || data["message"] || data["erro"] || data["msgs"]&.first
    end
    raise Correios::Error, message.presence || "Não foi possível consultar os Correios."
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise Correios::Error, "Os Correios estão temporariamente indisponíveis."
  end

  def response_status(response)
    response.respond_to?(:code) ? response.code.to_i : response.status.to_i
  end

  def parse_price(value)
    BigDecimal(value.to_s.delete(".").tr(",", "."))
  end

  def normalize_zipcode(value)
    zipcode = value.to_s.gsub(/\D/, "")
    raise Correios::Error, "CEP inválido." unless zipcode.match?(/\A\d{8}\z/)

    zipcode
  end

  def price_base_url
    ENV.fetch("CORREIOS_PRICE_URL", PRICE_BASE_URL)
  end

  def deadline_base_url
    ENV.fetch("CORREIOS_DEADLINE_URL", DEADLINE_BASE_URL)
  end
end
