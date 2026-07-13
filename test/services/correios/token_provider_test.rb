require "test_helper"

class Correios::TokenProviderTest < ActiveSupport::TestCase
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

    def post(url, options)
      @requests << [ url, options ]
      @responses.shift
    end
  end

  setup do
    @now = Time.zone.parse("2026-07-13 12:00:00")
    @cache = ActiveSupport::Cache::MemoryStore.new
  end

  test "generates and caches a bearer token using basic authentication" do
    http = FakeHttp.new([
      FakeResponse.new(201, {
        "token" => "bearer-token",
        "expiraEm" => (@now + 1.hour).iso8601
      })
    ])
    provider = provider_for(http)

    assert_equal "bearer-token", provider.token
    assert_equal "bearer-token", provider.token
    assert_equal 1, http.requests.size
    assert_equal Correios::TokenProvider::TOKEN_URL, http.requests.first.first
    assert_equal "Basic dXNlcjphY2Nlc3MtY29kZQ==", http.requests.first.last[:headers]["Authorization"]
  end

  test "renews a token close to expiration" do
    @cache.write(
      Correios::TokenProvider::CACHE_KEY,
      { "token" => "old-token", "expires_at" => (@now + 4.minutes).iso8601 }
    )
    http = FakeHttp.new([
      FakeResponse.new(201, {
        "token" => "new-token",
        "expiraEm" => (@now + 1.hour).iso8601
      })
    ])

    assert_equal "new-token", provider_for(http).token
    assert_equal 1, http.requests.size
  end

  test "requires credentials without making a request" do
    http = FakeHttp.new([])
    provider = Correios::TokenProvider.new(username: nil, access_code: nil, http: http, cache: @cache)

    error = assert_raises(Correios::Error) { provider.token }

    assert_equal "As credenciais dos Correios não foram configuradas.", error.message
    assert_empty http.requests
  end

  private

  def provider_for(http)
    Correios::TokenProvider.new(
      username: "user",
      access_code: "access-code",
      http: http,
      cache: @cache,
      now: -> { @now }
    )
  end
end
