module Connectors
  class Mailchimp
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
      "mailchimp"
    end

    def description
      auth.extra.raw_info.account_name
    end

    def account_identifiers
      {
        login_id:     auth.extra.metadata.login.login_id,
        login_name:   auth.extra.metadata.login.login_name,
        api_endpoint: auth.extra.metadata.api_endpoint,
        account_id:   auth.extra.raw_info.account_id,
        name:         auth.extra.raw_info.account_name,
        role:         auth.extra.raw_info.role,
        avatar_url:   auth.extra.metadata.login.avatar,
      }
    end

    def credential_details
      {
        api_key: "#{auth.credentials.token}-#{auth.extra.metadata.dc}",
        client_id:     ENV.fetch("MAILCHIMP_CLIENT_ID"),
        client_secret: ENV.fetch("MAILCHIMP_CLIENT_SECRET"), # TODO: Decide if we store the client_secret in the database or not
      }
    end
  end
end
