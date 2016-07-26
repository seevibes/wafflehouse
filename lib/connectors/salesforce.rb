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
      auth.extra.display_name
    end

    def account_identifiers
      {
        name: auth.extra.display_name,
        email: auth.extra.email,
        id: auth.extra.id,
        organisation_id: auth.extra.organization_id,
        avatar_url: auth.extra.photos.picture
      }
    end

    def credential_details
      {
        oauth_token: auth.credentials.token,
        expires: auth.credentials.expires,
        instance_url: auth.credentials.instance_url
      }
    end
  end
end