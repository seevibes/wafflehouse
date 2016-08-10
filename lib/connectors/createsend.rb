module Connectors
  class Createsend
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
      "createsend"
    end

    def description
      "createsend mailinglist"
    end

    def account_identifiers
      {
        #there is nothing giving by omniauth that we could use
      }
    end

    def credential_details
      {

        refresh_token: auth.credentials.refresh_token,
        oauth_token: auth.credentials.token,
        expires: auth.credentials.expires_at,
      }
    end
  end
end