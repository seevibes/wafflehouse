module Connectors
  #
  # SETUP
  # you'll need an environment variable ZENDESK_API_TOKEN
  # that you can found https://{site_name}.zendesk.com/agent/admin/api
  #
  class Zendesk
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
      "zendesk"
    end

    def description
      auth.extra.raw_info.account_name
    end

    def account_identifiers
      {
        url:          auth.extra.raw_info.url,
        id:           auth.extra.raw_info.id,
        name:         auth.extra.raw_info.name,
        role:         auth.extra.raw_info.role.name,
        site:         auth.info.site,
      }
    end

    def credential_details
      {
        api_token: ENV.fetch("ZENDESK_API_TOKEN"),
        username:  auth.credentials.token,
        secret:    auth.credentials.secret,
      }
    end
  end
end