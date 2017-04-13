module ExternalServiceNew
  class HubspotContactsResponse
    HUBSPOT = 'hubspot'

    attr_reader :contacts, :vid_offset
    def initialize(response)
      @contacts = response["contacts"]
      @has_more = response["has-more"]
      @vid_offset = has_more? ? Integer(response["vid-offset"]) : nil
    end

    def has_more?
      @has_more
    end

    def each_valid_email(&block)
      contacts.each do |contact|
        next unless has_valid_email?(contact)

        yield email(contact)
      end
    end

    def format_for_analytics
      contacts_with_valid_email.map do |contact|

        # Never store emails in clear text
        email_SHA256 = StringHelpers.normalized_SHA256(email(contact))
        contact["properties"]["email"]["value"] = email_SHA256

        [
          email_SHA256,
          HUBSPOT,
          contact.to_json
        ]
      end
    end


    private

    def contacts_with_valid_email
      contacts.select{ |contact| has_valid_email?(contact) }
    end

    def email(contact)
      contact.try(:[], "properties").try(:[], "email").try(:[],"value")
    end

    def has_valid_email?(contact)
      email(contact).present?
    end
  end
end