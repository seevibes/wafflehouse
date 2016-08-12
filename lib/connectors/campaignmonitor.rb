module Connectors
  class CampaignMonitor
    def self.call(params:, auth:)
      new(params, auth)
    end

    def initialize(params, auth)
      @params        = params
      @auth          = auth
      @refresh_token = auth.credentials.refresh_token
      @oauth_token   = auth.credentials.token
      @expires       = auth.credentials.expires_at
    end

    attr_reader :params, :auth
    private :params, :auth

    def connector_code
      "campaignmonitor"
    end

    def description
      "campaignmonitor mailinglist"
    end

    def account_identifiers
      {
        #there is nothing from Omniauth that we could use
      }
    end

    def credential_details
      {
        refresh_token: @refresh_token,
        oauth_token: @oauth_token,
        expires: @expires,
      }
    end
  end
end