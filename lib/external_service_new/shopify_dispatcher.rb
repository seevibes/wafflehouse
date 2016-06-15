require "seevibes/oj"
require "rest_client"
require "seevibes/external_service/rest_client_dispatcher"

module ExternalServiceNew
  class ShopifyDispatcher < RestClientDispatcher

    attr_reader :shop_url
    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5, client: RestClient)
      @access_token = credential_details.fetch("token")
      @shop_url     = account_identifiers.fetch("shop_url")
      @client       = client

      super(sleep_time_seconds)
    end

    def dispatch(method, path)
      super() do
        response = @client.public_send(
          method,
          "https://#{@shop_url}/#{path.sub(%r{^/}, "")}", # TODO filters
          content_type: :json,
          accept: :json,
          "X-Shopify-Access-Token": @access_token)

        # Leaky bucket algorithm with a maximum of 40
        # https://docs.shopify.com/api/guides/api-call-limit
        sleep 10 if response.headers[:x_shopify_shop_api_call_limit].to_i >= 39
        Oj.load(response)
      end
    end
  end
end
