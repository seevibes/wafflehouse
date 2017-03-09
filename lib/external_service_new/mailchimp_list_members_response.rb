module ExternalServiceNew
  class MailchimpListMembersResponse

    def initialize(batch_members)
      @members = batch_members
    end

    def size
      @members.size
    end

    def each_valid_email(&block)
      @members.each do |member|
        next unless member["email_address"]
        yield member["email_address"]
      end
    end

    def format_for_analytics
      members_with_valid_email.map do |member|

        # Never store emails in clear text
        email_SHA256 = StringHelpers.normalized_SHA256(member["email_address"])
        member["email_address"] = email_SHA256

        [
          email_SHA256,
          'mailchimp',
          member.to_json
        ]
      end
    end


    private

    def members_with_valid_email
      @members.select{ |member| !member["email_address"].nil? }
    end
  end
end