require "test_helper"

class Correios::ClientTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:status, :parsed_response) do
    def success?
      status.between?(200, 299)
    end
  end

  class FakeHttp
    attr_reader :requests

    def initialize(responses)
      @responses = responses
      @requests = []
    end

    def get(url, options)
      @requests << [ url, options ]
      @responses.shift
    end
  end

  class FakeTokenProvider
    attr_reader :invalidations

    def initialize(token = "token")
      @token = token
      @invalidations = 0
    end

    def token
      @token
    end

    def invalidate!
      @invalidations += 1
    end
  end

  test "returns PAC and SEDEX quotes with price and deadline" do
    http = FakeHttp.new([
      FakeResponse.new(200, { "pcFinal" => "18,75" }),
      FakeResponse.new(200, { "prazoEntrega" => 7 }),
      FakeResponse.new(200, { "pcFinal" => "29,40" }),
      FakeResponse.new(200, { "prazoEntrega" => 3 })
    ])
    client = Correios::Client.new(token_provider: FakeTokenProvider.new, origin_zipcode: "17509-031", http: http)
    package = Correios::Package.new(weight_grams: 300, length_cm: 20, width_cm: 15, height_cm: 5)

    quotes = client.quotes(destination_zipcode: "01001-000", package: package)

    assert_equal %w[PAC SEDEX], quotes.map(&:service_name)
    assert_equal [ BigDecimal("18.75"), BigDecimal("29.40") ], quotes.map(&:price)
    assert_equal [ 7, 3 ], quotes.map(&:delivery_days)
    assert_equal "Bearer token", http.requests.first.last[:headers]["Authorization"]
    assert_equal "17509031", http.requests.first.last[:query][:cepOrigem]
    assert_equal "01001000", http.requests.first.last[:query][:cepDestino]
  end

  test "rejects unsupported service codes" do
    client = Correios::Client.new(token_provider: FakeTokenProvider.new, http: FakeHttp.new([]))
    package = Correios::Package.new(weight_grams: 300, length_cm: 20, width_cm: 15, height_cm: 5)

    error = assert_raises(Correios::Error) do
      client.quote(service_code: "invalid", destination_zipcode: "01001000", package: package)
    end

    assert_equal "Serviço de entrega inválido.", error.message
  end

  test "refreshes the token and retries once when authorization is stale" do
    http = FakeHttp.new([
      FakeResponse.new(401, { "message" => "Token expirado" }),
      FakeResponse.new(200, { "pcFinal" => "18,75" }),
      FakeResponse.new(200, { "prazoEntrega" => 7 })
    ])
    token_provider = FakeTokenProvider.new
    client = Correios::Client.new(token_provider: token_provider, http: http)
    package = Correios::Package.new(weight_grams: 300, length_cm: 20, width_cm: 15, height_cm: 5)

    quote = client.quote(service_code: "03298", destination_zipcode: "01001000", package: package)

    assert_equal "PAC", quote.service_name
    assert_equal 1, token_provider.invalidations
    assert_equal 3, http.requests.size
  end
end
