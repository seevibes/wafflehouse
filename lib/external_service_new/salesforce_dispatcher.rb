require "seevibes/oj"
require "rest_client"
require "seevibes/external_service/rest_client_dispatcher"
require "restforce"


module ExternalServiceNew
  class SalesforceDispatcher < RestClientDispatcher

    attr_reader :account_name

    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5, &block)
      @credential_details = credential_details
      @account_name = account_identifiers["name"]
      client_params = @credential_details.symbolize_keys.slice(:oauth_token, :instance_url, :refresh_token)

      @client = ::Restforce.new(client_params.merge(authentication_callback: authentication_callback(&block)))
      super(sleep_time_seconds)
    end

    def authentication_callback(&block)
      -> (x) do
        block.call(@credential_details.merge(oauth_token: x.to_s)) if block_given?
      end
    end


    def dispatch(method, path)
      super() do
        @client.send(method, path) # eg path = "Contact"
      end
    end
  end
end
