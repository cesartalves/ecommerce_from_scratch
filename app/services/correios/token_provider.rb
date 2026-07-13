require "base64"
require "time"

class Correios::TokenProvider
  TOKEN_URL = "https://api.correios.com.br/token/v1/autentica".freeze
  CACHE_KEY = "correios/bearer-token/v1".freeze
  REFRESH_BUFFER = 5.minutes
  MUTEX = Mutex.new

  def initialize(
    username: ENV["CORREIOS_USERNAME"],
    access_code: ENV["CORREIOS_ACCESS_CODE"],
    http: HTTParty,
    cache: Rails.cache,
    now: -> { Time.current }
  )
    @username = username
    @access_code = access_code
    @http = http
    @cache = cache
    @now = now
  end

  def token
    cached_token || MUTEX.synchronize { cached_token || request_token }
  end

  def invalidate!
    @cache.delete(CACHE_KEY)
  end

  private

  def cached_token
    payload = @cache.read(CACHE_KEY)
    return unless payload.is_a?(Hash)

    expires_at = parse_expiration(payload["expires_at"] || payload[:expires_at])
    value = payload["token"] || payload[:token]
    value if value.present? && expires_at > current_time + REFRESH_BUFFER
  rescue ArgumentError, TypeError
    nil
  end

  def request_token
    validate_credentials!
    response = @http.post(
      token_url,
      headers: {
        "Accept" => "application/json",
        "Authorization" => "Basic #{Base64.strict_encode64("#{@username}:#{@access_code}")}"
      },
      timeout: 8
    )
    data = response.parsed_response

    unless response.success? && data.is_a?(Hash)
      raise Correios::Error, response_error(data) || "Não foi possível autenticar nos Correios."
    end

    value = data["token"]
    expires_at = parse_expiration(data["expiraEm"])
    raise Correios::Error, "Os Correios retornaram um token inválido." if value.blank? || expires_at <= current_time

    @cache.write(
      CACHE_KEY,
      { "token" => value, "expires_at" => expires_at.iso8601 },
      expires_in: [ expires_at - current_time - REFRESH_BUFFER, 1.second ].max
    )
    value
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError
    raise Correios::Error, "A autenticação dos Correios está temporariamente indisponível."
  rescue ArgumentError, TypeError
    raise Correios::Error, "Os Correios retornaram um token inválido."
  end

  def validate_credentials!
    return if @username.present? && @access_code.present?

    raise Correios::Error, "As credenciais dos Correios não foram configuradas."
  end

  def parse_expiration(value)
    Time.iso8601(value.to_s)
  end

  def response_error(data)
    return unless data.is_a?(Hash)

    data["msgErro"] || data["message"] || data["mensagem"] || data["msgs"]&.first
  end

  def current_time
    @now.call
  end

  def token_url
    ENV.fetch("CORREIOS_TOKEN_URL", TOKEN_URL)
  end
end
