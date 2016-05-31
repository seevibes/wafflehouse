module Connectors
  class Shopify
    def self.call(params:, auth:)
      new(params, auth)
    end

    def initialize(params, auth)
      @params = params
      @auth   = auth
    end

    attr_reader :params, :auth
    private :params, :auth

    def connector_code
      "shopify"
    end

    def description
      "#{auth.uid}"
    end

    def account_identifiers
      { "shop_url" => auth.uid }
    end

    def credential_details
      {
        "token"         => auth.credentials.token,
        "api_key"       => ENV.fetch("SHOPIFY_API_KEY"),
        "shared_secret" => ENV.fetch("SHOPIFY_SHARED_SECRET"),
      }
    end
  end
end
