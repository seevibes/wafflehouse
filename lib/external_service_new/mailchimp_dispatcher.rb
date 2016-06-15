require "seevibes/oj"
require "rest_client"
require "seevibes/external_service/rest_client_dispatcher"

module ExternalServiceNew
  class MailchimpDispatcher < RestClientDispatcher
    MAILCHIMP_API_URL = "api.mailchimp.com/3.0"

    # The signature has to be the same for all dispatchers even when account_identifiers is not needed
    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5, client: RestClient)
      @api_key = credential_details.fetch("api_key")
      @client  = client


      super(sleep_time_seconds)
    end

    def dispatch(method, path)
      super() do
        response = @client.public_send(
          method,
          "https://:#{@api_key}@#{@api_key.split("-").last}.#{MAILCHIMP_API_URL}/#{path.sub(%r{^/},"")}")

        Oj.load(response)
      end
    end
  end
end
