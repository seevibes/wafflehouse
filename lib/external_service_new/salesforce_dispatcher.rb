require "oj"
require "rest_client"
require "external_service_new/rest_client_dispatcher"
require "restforce"


module ExternalServiceNew
  class SalesforceDispatcher < RestClientDispatcher

    attr_reader :account_name

    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5)

      @account_name = account_identifiers["name"]
      @client = ::Restforce.new(credential_details.symbolize_keys.slice(:oauth_token, :instance_url))
      super(sleep_time_seconds)
    end


    def dispatch(method, path)
      super() do
        @client.send(method, path) # eg path = "Contact"
      end
    end
  end
end
