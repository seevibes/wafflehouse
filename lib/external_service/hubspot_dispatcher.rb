require "seevibes/oj"
require "rest_client"
require "seevibes/external_service/rest_client_dispatcher"

module ExternalService
  class HubspotDispatcher < RestClientDispatcher
    EXPIRES_IN = 28800
    HUBSPOT_API_URL = "https://api.hubapi.com/"

    def initialize(account_identifiers:, credential_details:, sleep_time_seconds: 5, client: RestClient)
      @refresh_token = credential_details.fetch("refresh_token")
      @client        = client

      super(sleep_time_seconds)
    end

    def dispatch(method, path)
      super() do
        response = begin
          @access_token ||= fetch_new_access_token

          @client.public_send(method, "#{HUBSPOT_API_URL}#{path.sub(%r{^/},"")}#{path["?"] ? "&" : "?"}access_token=#{@access_token}")
        rescue RestClient::Unauthorized => e
          @access_token = nil
          raise
        end
        # Rate-limited to 10000 / 24h
        sleep 9

        Oj.load(response)
      end
    end

    private

    def fetch_new_access_token
      response = Oj.load(
        @client.post(
          "#{HUBSPOT_API_URL}/auth/v1/refresh",
          refresh_token: @refresh_token,
          client_id: ENV.fetch("HUBSPOT_CLIENT_ID"),
          grant_type: "refresh_token"))

      response["access_token"]
    end
  end
end
