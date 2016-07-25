require "seevibes/oj"
require "rest_client"
require "seevibes/external_service/rest_client_dispatcher"
require ""

module ExternalServiceNew
  class Salesforce < RestClientDispatcher

    attr_reader :account_id
    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5)
      @account_id = account_identifiers.fetch("account_id")
      @client       = Databasedotcom::Client.new(
        client_id: credential_details.fetch("client_id"),
        client_secret: credential_details.fetch("client_secret")
      )
      @client.authenticate(token: credential_details.fetch(:token), :instance_url => "http://na1.salesforce.com")
      @contact_class = client.materialize("Contact")
      super(sleep_time_seconds)
    end

    def dispatch(method, path)
      super() do
        @resource_class = client.materialize(path) # eg path = "Contact"
        @contact_class.send(method) # eg method = :all
      end
    end
  end
end
