module Connectors
  class Hubspot
    # Returns an instance of an object that responds to the Seevibes Connector Protocol.
    #
    # Seevibes Connector Protocol instances must implement the following methods:
    #
    # * `#description`:         Returns a plain-text description of the connection. The text won't be localized.
    #                           Returning the account's name is a perfectly valid option, as well as the empty string.
    #                           Must not return nil; the empty string is an acceptable return value.
    #
    # * `#account_identifiers`: Returns a Ruby Hash that describes the account to which this instance is connected.
    #                           This exact Hash (after serialization to JSON) will be provided to the Dispatcher.
    #                           Must not return nil; the empty hash is an acceptable return value.
    #
    # * `#credential_details`:  Returns a Ruby Hash with all the information needed to make API calls later.
    #                           This exact Hash (after serialization to JSON) will be provided to the Dispatcher.
    #                           Must not return nil; the empty hash is an acceptable return value.
    #
    # Seevibes Connector Protocol instances may not make HTTP requests.
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
      "hubspot"
    end

    def description
      "Hub ID: #{params.fetch("hub_id")}"
    end

    def account_identifiers
      { "hub_id" => params.fetch("hub_id") }
    end

    def credential_details
      { "client_id" => ENV.fetch("HUBSPOT_CLIENT_ID"), "refresh_token" => auth.credentials.refresh_token }
    end
  end
end
