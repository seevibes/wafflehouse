module Connectors
  class Salesforce
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
      "salesforce"
    end

    def description

    end

    def account_identifiers
      {

      }
    end

    def credential_details
      {

      }
    end
  end
end