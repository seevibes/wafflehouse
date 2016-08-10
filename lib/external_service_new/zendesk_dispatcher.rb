require "oj"
require "rest_client"
require "external_service_new/rest_client_dispatcher"

module ExternalServiceNew
  class ZendeskDispatcher < RestClientDispatcher
    attr_reader :site_url

    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5, client: RestClient)

      account_identifiers = account_identifiers.symbolize_keys
      credential_details = credential_details.symbolize_keys
      @site_url = account_identifiers.fetch(:site)
      @api_token = credential_details.fetch(:api_token)
      @client = ZendeskAPI::Client.new do |config|
        config.url = "#{@site_url}/api/v2"
        config.username = credential_details.fetch(:username)
        config.token = credential_details.fetch(:api_token)
      end
    end

    def dispatch(method, path)
      super() do
        @client.search(method => path)
      end
    end
  end
end
